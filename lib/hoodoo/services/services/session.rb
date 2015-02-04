########################################################################
# File::    session.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Container for information about the context in which a
#           service is called.
# ----------------------------------------------------------------------
#           04-Feb-2015 (ADH): Created.
########################################################################

require 'dalli'

module Hoodoo
  module Services

    class Session

      # Time To Live: Number of seconds for which a session remains valid
      # after being saved. Only applicable from the save time onwards in
      # stores that support TTL such as memcached - see #save_to_memcached.
      #
      TTL = 172800 # 48 hours

      # A Session must have its own UUID. This is that ID.
      #
      attr_accessor :session_id

      # A Hash with session-creator defined key/value pairs that define
      # the _identity_ of the session holder. This is usually related to
      # a Caller resource instance - see also
      # Hoodoo::Data::Resources::Caller - and will often contain a
      # Caller resource instance's UUID, amongst other data.
      #
      # The Hash describes "who the session's owner is".
      #
      # All Hash keys _must_ be Strings.
      #
      attr_accessor :identity

      # A Hoodoo::Services::Permissions instance.
      #
      # The instance describes "what the session session is allowed to do".
      #
      attr_accessor :permissions

      # A Hash with session-creator defined values that describe the
      # _scoping_, that is, visbility of data, for the session. Its
      # contents relate to service resource interface descriptions (see
      # the DSL for Hoodoo::Services::Interface) and may be partially or
      # entirely supported by the ActiveRecord finder extensions in
      # Hoodoo::ActiveRecord::Finder.
      #
      # The Hash describes the "data that the session can 'see'".
      #
      # All Hash keys _must_ be Strings.
      #
      attr_accessor :scoping

      # Connection URL for memcached.
      #
      # If you are using memcached for a session store, you can set the
      # memcached connection URL either through this accessor, or via the
      # object's constructor.
      #
      attr_accessor :memcached_url

      # Create a new instance.
      #
      # +options+::       Optional Hash of options, described below.
      #
      # Options are:
      #
      # +session_id+::    UUID of this session. If unset, a new UUID is
      #                   generated for you. You can read the UUID with the
      #                   #session_id accessor method.
      #
      # +memcached_url+:: URL for memcached connections; required if you want
      #                   to use the #load_from_memcached! or #save_to_memcached
      #                   methods.
      #
      def initialize( options = {} )
        self.session_id    = options[ :session_id    ] || Hoodoo::UUID.generate()
        self.memcached_url = options[ :memcached_url ]
      end

      # Save this session to memcached, in a manner that will allow it to
      # be loaded by #load_from_memcached! later.
      #
      # The Hoodoo::Services::Session::TTL constant determines how long the
      # key lives in memcached.
      #
      # If successful, returns a Time instance that describes a time which
      # is (within code execution speed tolerances) equal to or (more
      # likely) just after the time at which memcached would expire the
      # session record.
      #
      # If unsuccessful, the method raises an exception or returns +nil+.
      #
      def save_to_memcached
        client = self.class.connect_to_memcached( self.memcached_url() )

        begin

          # Set in memcached first. This starts the "expiry counter running".
          # Then calculate the local 'expires at' time. This guarantees that
          # the 'expires at' time will be on *or after* the actual memcached
          # expiry, which is what we want.
          #
          success = memcache.set( self.key_for_memcached( session_id ),
                                  self.to_h(),
                                  Hooodoo::Services::Session::TTL )

          if ( ! success )
            return nil
          else
            return ::Time.now + TTL
          end

        rescue Exception => exception

          # Log error and return nil if the session can't be parsed
          #
          Hoodoo::Services::Middleware.logger.warn(
            'Hoodoo::Services::Session\#save_to_memcached: Session saving failed - connection fault or session corrupt',
            exception
          )

          return nil
        end
      end

      # Load session data into this instance, overwriting instance values
      # if the session is found. Raises an exception if there is a problem
      # connecting to memcached. A memcached connection URL must have been
      # set through the constructor or #memcached_url accessor first.
      #
      # Returns 'this instance' for convenience on success, or +nil+ if
      # the session cannot be loaded from memcached (session not found).
      #
      def load_from_memcached!( session_id )
        client = self.class.connect_to_memcached( self.memcached_url() )

        begin

          session_hash = client.get( self.key_for_memcached( session_id ) )

          if session_hash.nil?
            return nil
          else
            self.from_h( session_hash )
            return self
          end

        rescue Exception => exception

          # Log error and return nil if the session can't be parsed
          #
          Hoodoo::Services::Middleware.logger.warn(
            'Hoodoo::Services::Session\#load_from_memcached!: Session loading failed - connection fault or session corrupt',
            exception
          )

          return nil
        end
      end

      # Represent this session's data as a Hash, for uses such as
      # storage in memcached or loading into another session instance.
      # See also #from_h.
      #
      def to_h
        {
          'session_id'  => self.session_id(),
          'identity'    => Hoodoo::Utilities.stringify( self.identity() ),
          'scoping'     => Hoodoo::Utilities.stringify( self.scoping()  ),
          'permissions' => self.permissions.to_h()
        }
      end

      # Load session parameters from a given Hash, of the form set by
      # #to_h.
      #
      # If appropriate Hash keys are present, will set any or all of
      # #session_id, #identity, #scoping and #permissions.
      #
      def from_h( hash )
        hash = Hoodoo::Utilities.stringify( hash )

        self.session_id = hash[ 'session_id' ] if hash.has_key?( 'session_id' )
        self.identity   = hash[ 'identity'   ] if hash.has_key?( 'identity'   )
        self.scoping    = hash[ 'scoping'    ] if hash.has_key?( 'scoping'    )

        if hash.has_key?( 'permissions' )
          self.permissions = Hoodoo::Services::Permissions.new( hash[ 'permissions' ] )
        end
      end

    private

      # Connect to the memcached server. Returns a new Dalli client
      # instance. Raises an exception if no connection can be established.
      #
      # +url+:: Connection URL for memcached.
      #
      def self.connect_to_memcached( url )
        if url.nil? || url.empty?
          raise 'Hoodoo::Services::Session.connect_to_memcached: The memcached connection URL is nil or empty'
        end

        stats = nil

        begin
          client = ::Dalli::Client.new(
            url,
            { :compress => false, :serializer => JSON }
          )

          stats = client.stats()

        rescue Exception => e
          stats = nil

        end

        if stats.nil?
          raise "Hoodoo::Services::Session.connect_to_memcached: Cannot connect to memcached on URL '#{ url }'"
        else
          return client
        end
      end

      # For a given session ID, return the key (String) that must be
      # used for saving to or loading from memcached.
      #
      def key_for_memcached( session_id )
        "platform_session_#{ session_id }"
      end
    end
  end
end
