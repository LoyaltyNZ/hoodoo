########################################################################
# File::    session.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Container for information about the context in which a
#           service is called.
# ----------------------------------------------------------------------
#           04-Feb-2015 (ADH): Created.
########################################################################

require 'ostruct'
require 'dalli'

module Hoodoo
  module Services

    # A container for functionality related to a context session.
    #
    class Session

      # Time To Live: Number of seconds for which a session remains valid
      # after being saved. Only applicable from the save time onwards in
      # stores that support TTL such as Memcached - see #save_to_memcached.
      #
      TTL = 172800 # 48 hours

      # A Session must have its own UUID. This is that ID.
      #
      attr_accessor :session_id

      # An OpenStruct instance with session-creator defined key/value pairs
      # that define the _identity_ of the session holder. This is usually
      # related to a Caller resource instance - see also
      # Hoodoo::Data::Resources::Caller - and will often contain a Caller
      # resource instance's UUID, amongst other data.
      #
      # The object describes "who the session's owner is".
      #
      attr_reader :identity

      # Set the identity data via a Hash of key/value pairs - see also
      # #identity.
      #
      def identity=( hash )
        @identity = OpenStruct.new( hash )
      end

      # A Hoodoo::Services::Permissions instance.
      #
      # The instance describes "what the session session is allowed to do".
      #
      attr_accessor :permissions

      # An OpenStruct instance with session-creator defined values that
      # describe the _scoping_, that is, visbility of data, for the session.
      # Its contents relate to service resource interface descriptions (see
      # the DSL for Hoodoo::Services::Interface) and may be partially or
      # entirely supported by the ActiveRecord finder extensions in
      # Hoodoo::ActiveRecord::Finder.
      #
      # The object describes the "data that the session can 'see'".
      #
      attr_accessor :scoping

      # Set the scoping data via a Hash of key/value pairs - see also
      # #scoping.
      #
      def scoping=( hash )
        @scoping = OpenStruct.new( hash )
      end

      # The expiry date for this session - the session should be considered
      # expired at or after this date. Some session stores may support
      # automatic expiry of session data, but there may be a small window
      # between the expiry date passing and the store expiring the data; so
      # always check the expiry.
      #
      # Only set when the session is saved (or loaded from a representation
      # that includes an existing expiry date). See e.g.:
      #
      # * #save_to_memcached
      #
      # The value is a Time instance in UTC. If +nil+, the session has not
      # yet been saved.
      #
      attr_reader :expires_at

      # Connection URL for Memcached.
      #
      # If you are using Memcached for a session store, you can set the
      # Memcached connection URL either through this accessor, or via the
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
      # +memcached_url+:: URL for Memcached connections; required if you want
      #                   to use the #load_from_memcached! or #save_to_memcached
      #                   methods.
      #
      def initialize( options = {} )
        self.session_id    = options[ :session_id    ] || Hoodoo::UUID.generate()
        self.memcached_url = options[ :memcached_url ]
      end

      # Save this session to Memcached, in a manner that will allow it to
      # be loaded by #load_from_memcached! later.
      #
      # The Hoodoo::Services::Session::TTL constant determines how long the
      # key lives in Memcached.
      #
      # If successful, returns the now-set/now-updated value of #expires_at.
      #
      # If unsuccessful, the method raises an exception or returns +nil+.
      #
      def save_to_memcached
        client = self.class.connect_to_memcached( self.memcached_url() )

        begin

          # Must set this before saving, even though the delay between
          # setting this value and Memcached actually saving the value
          # with a TTL will mean that Memcached expires the key slightly
          # *after* the time we record.

          @expires_at = ( ::Time.now + TTL ).utc()

          success = memcache.set( session_id,
                                  self.to_h(),
                                  Hooodoo::Services::Session::TTL )

          if ( ! success )
            return nil
          else
            return @expires_at
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
      # connecting to Memcached. A Memcached connection URL must have been
      # set through the constructor or #memcached_url accessor first.
      #
      # Returns 'this instance' for convenience on success, or +nil+ if
      # the session cannot be loaded from Memcached (session not found).
      #
      def load_from_memcached!( session_id )
        client = self.class.connect_to_memcached( self.memcached_url() )

        begin

          session_hash = client.get( session_id )

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

      # Has this session expired? Only valid if an expiry date is set;
      # see #expires_at.
      #
      # Returns +true+ if the session has expired, or +false+ if it has
      # either not expired, or has no expiry date set yet.
      #
      def expired?
        exp = self.expires_at()
        now = Time.now.utc

        return exp.nil? || now < exp
      end

      # Represent this session's data as a Hash, for uses such as
      # storage in Memcached or loading into another session instance.
      # See also #from_h.
      #
      def to_h
        {
          'session_id'  => self.session_id,
          'identity'    => self.identity.to_h(),
          'scoping'     => self.scoping.to_h(),
          'permissions' => self.permissions.to_h(),
          'exipres_at'  => self.expires_at.iso8601
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

        if hash.has_key?( 'expires_at' )
          begin
            @expires_at = Time.parse( hash[ 'expires_at' ] ).utc()
          rescue
            @expires_at = nil
          end
        end
      end

    private

      # Connect to the Memcached server. Returns a new Dalli client
      # instance. Raises an exception if no connection can be established.
      #
      # +url+:: Connection URL for Memcached.
      #
      def self.connect_to_memcached( url )
        if url.nil? || url.empty?
          raise 'Hoodoo::Services::Session.connect_to_memcached: The Memcached connection URL is nil or empty'
        end

        stats = nil

        begin
          client = ::Dalli::Client.new(
            url,
            {
              :compress   => false,
              :serializer => JSON,
              :namespace  => :nz_co_loyalty_hoodoo_session_
            }
          )

          stats = client.stats()

        rescue Exception => e
          stats = nil

        end

        if stats.nil?
          raise "Hoodoo::Services::Session.connect_to_memcached: Cannot connect to Memcached on URL '#{ url }'"
        else
          return client
        end
      end
    end
  end
end
