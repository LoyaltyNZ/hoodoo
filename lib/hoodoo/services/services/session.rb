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

      # A Session must have its own UUID.
      #
      attr_accessor :session_id

      # A Session must always refer to a Caller instance by UUID.
      #
      attr_accessor :caller_id

      # Callers can change; if so, related sessions must be invalidated.
      # This must be achieved by keeping a version count on the Caller. A
      # session is associated with a particular Caller version and if the
      # version changes, associated sessions are flushed.
      #
      # If you _change_ a Caller version in a Session, you _really_ should
      # call #save_to_memcached as soon as possible afterwards so that the
      # change gets recognised in Memcached.
      #
      attr_accessor :caller_version

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

      # The creation date of this session instance as a Time instance in
      # UTC.
      #
      attr_reader :created_at

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

      # Connection IP address/port String for Memcached.
      #
      # If you are using Memcached for a session store, you can set the
      # Memcached connection host either through this accessor, or via the
      # object's constructor.
      #
      attr_accessor :memcached_host

      # Create a new instance.
      #
      # +options+::       Optional Hash of options, described below.
      #
      # Options are:
      #
      # +session_id+::     UUID of this session. If unset, a new UUID is
      #                    generated for you. You can read the UUID with
      #                    the #session_id accessor method.
      #
      # +caller_id+::      UUID of the Caller instance associated with this
      #                    session. This can be set either now or later, but
      #                    the session cannot be saved without it.
      #
      # +caller_version+:: Version of the Caller instance; defaults to zero.
      #
      # +memcached_host+:: Host for Memcached connections; required if you
      #                    want to use the #load_from_memcached! or
      #                    #save_to_memcached methods.
      #
      def initialize( options = {} )
        @created_at = Time.now.utc

        self.session_id     = options[ :session_id     ] || Hoodoo::UUID.generate()
        self.memcached_host = options[ :memcached_host ]
        self.caller_id      = options[ :caller_id      ]
        self.caller_version = options[ :caller_version ] || 0
      end

      # Save this session to Memcached, in a manner that will allow it to
      # be loaded by #load_from_memcached! later.
      #
      # A session can only be saved if it has a Caller ID - see #caller_id=
      # or the options hash passed to the constructor.
      #
      # The Hoodoo::Services::Session::TTL constant determines how long the
      # key lives in Memcached.
      #
      # If successful, returns the now-set/now-updated value of #expires_at.
      #
      # If unsuccessful, the method raises an exception or returns +nil+.
      #
      def save_to_memcached
        if self.caller_id.nil?
          raise 'Hoodoo::Services::Session\#save_to_memcached: Cannot save this session as it has no assigned Caller UUID'
        end

        mclient = self.class.connect_to_memcached( self.memcached_host() )

        begin

          # (1) Get the current version from Memcached.
          #
          # (2) If it is missing or less than our version that's OK, just
          #     set the version data.
          #
          # (3) If it is greater than our version we are already stale!
          #     Race condition - make the decision to update 'self' to
          #     the newer version and go with that since the session is
          #     assumed not under use before saving.

          cached_version = load_caller_version_from_memcached( mclient, self.caller_id )
          self.caller_version = cached_version if cached_version != nil && cached_version > self.caller_version

          success = save_caller_version_to_memcached( mclient, self.caller_id, self.caller_version )
          return nil unless success

          # Must set this before saving, even though the delay between
          # setting this value and Memcached actually saving the value
          # with a TTL will mean that Memcached expires the key slightly
          # *after* the time we record.

          @expires_at = ( ::Time.now + TTL ).utc()

          success = mclient.set( session_id,
                                 self.to_h(),
                                 Hooodoo::Services::Session::TTL )

          return nil unless success
          return @expires_at

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
      # connecting to Memcached. A Memcached connection host must have been
      # set through the constructor or #memcached_host accessor first.
      #
      # Returns:
      #
      # * +true+: The session data was loaded OK and is valid.
      #
      # * +false+: The session data was loaded, but is not valid; either
      #   the session has expired, or its Caller version mismatches the
      #   associated stored Caller version in Memcached.
      #
      # * +nil+: The session data could not be loaded (Memcached problem).
      #
      def load_from_memcached!( session_id )
        mclient = self.class.connect_to_memcached( self.memcached_host() )

        begin

          session_hash = memcached.get( session_id )

          if session_hash.nil?
            return nil
          else
            self.from_h( session_hash )
            return false if self.expired?

            cv = self.load_caller_version_from_memcached( mclient, self.caller_id )
            return false if cv.nil? || cv > self.caller_version

            return true
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
          'session_id'     => self.session_id,
          'caller_id'      => self.caller_id,
          'caller_version' => self.caller_version,

          'created_at'     => self.created_at.iso8601,
          'expires_at'     => self.expires_at.iso8601,

          'identity'       => self.identity.to_h(),
          'scoping'        => self.scoping.to_h(),
          'permissions'    => self.permissions.to_h(),
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

        self.session_id     = hash[ 'session_id'      ] if hash.has_key?( 'session_id'      )
        self.caller_id      = hash[ 'caller_id'       ] if hash.has_key?( 'caller_id'       )
        self.caller_version = hash[ 'caller_version'  ] if hash.has_key?( 'caller_version'  )

        if hash.has_key?( 'created_at' )
          begin
            @created_at = Time.parse( hash[ 'created_at' ] ).utc()
          rescue
            # Invalid time given; keep existing created_at date
          end
        end

        if hash.has_key?( 'expires_at' )
          begin
            @expires_at = Time.parse( hash[ 'expires_at' ] ).utc()
          rescue
            # Invalid time given; keep existing expired_at date
          end
        end

        self.identity = hash[ 'identity' ] if hash.has_key?( 'identity' )
        self.scoping  = hash[ 'scoping'  ] if hash.has_key?( 'scoping'  )

        if hash.has_key?( 'permissions' )
          self.permissions = Hoodoo::Services::Permissions.new( hash[ 'permissions' ] )
        end
      end

    private

      # Connect to the Memcached server. Returns a new Dalli client
      # instance. Raises an exception if no connection can be established.
      #
      # +host+:: Connection host (IP "address:port" String) for Memcached.
      #
      def self.connect_to_memcached( host )
        if host.nil? || host.empty?
          raise 'Hoodoo::Services::Session.connect_to_memcached: The Memcached connection host data is nil or empty'
        end

        stats = nil

        begin
          mclient = ::Dalli::Client.new(
            host,
            {
              :compress   => false,
              :serializer => JSON,
              :namespace  => :nz_co_loyalty_hoodoo_session_
            }
          )

          stats = mclient.stats()

        rescue Exception => e
          stats = nil

        end

        if stats.nil?
          raise "Hoodoo::Services::Session.connect_to_memcached: Cannot connect to Memcached at '#{ host }'"
        else
          return mclient
        end
      end

      # Return the Caller version for a given Caller ID via Memcached.
      # Returns "nil" if there are any errors or no version is stored.
      #
      # +mclient+::   A Dalli::Client instance to use for talking to
      #               Memcached.
      #
      # +caller_id+:: Caller UUID of interest.
      #
      def load_caller_version_from_memcached( mclient, caller_id )
        cv = begin
          verison_hash = mclient.get( self.caller_id )
          version_hash[ 'version' ] # Exception if version_hash is nil => will be rescued
        rescue
          nil
        end

        return cv
      end

      # Save the Caller version for a given Caller ID to Memcached.
      # Returns +true+ if successful, else +false+.
      #
      # Note that any existing record for the given Caller, if there
      # is one, is unconditionally overwritten.
      #
      # +mclient+::   A Dalli::Client instance to use for talking to
      #               Memcached.
      #
      # +caller_id+:: Caller UUID of interest.
      #
      # +cv+::        Version to save for that Caller UUID.
      #
      def save_caller_version_to_memcached( mclient, caller_id, cv )
        success = begin
          mclient.set(
            caller_id,
            { 'version' => cv }
          )
        rescue
          false
        end

        return success
      end

    end
  end
end
