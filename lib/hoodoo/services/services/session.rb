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
      # The instance describes "what the session is allowed to do".
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
      # +options+:: Optional Hash of options, described below.
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
      # Returns a symbol:
      #
      # * +:ok+: The session data was saved OK and is valid. There was either
      #   a Caller record with an earlier or matching value in Memcached, or
      #   no preexisting record of the Caller.
      #
      # * +:outdated+: The session data could not be saved because an existing
      #   Caller record was found in Memcached with a _newer_ version than
      #   'this' session, implying that the session is already outdated.
      #
      # * +:fail+: The session data could not be saved (Memcached problem).
      #
      def save_to_memcached
        if self.caller_id.nil?
          raise 'Hoodoo::Services::Session\#save_to_memcached: Cannot save this session as it has no assigned Caller UUID'
        end

        begin
          mclient = self.class.connect_to_memcached( self.memcached_host() )

          # Try to update the Caller version in Memcached using this
          # Session's data. If this fails, the Caller version is out of
          # date or we couldn't talk to Memcached. Either way, bail out.

          result = update_caller_version_in_memcached( self.caller_id,
                                                       self.caller_version,
                                                       mclient )

          return result unless result.equal?( :ok )

          # Must set this before saving, even though the delay between
          # setting this value and Memcached actually saving the value
          # with a TTL will mean that Memcached expires the key slightly
          # *after* the time we record.

          @expires_at = ( ::Time.now + TTL ).utc()

          return :ok if mclient.set( self.session_id,
                                     self.to_h(),
                                     TTL )

        rescue => exception

          # Log error and return nil if the session can't be parsed
          #
          Hoodoo::Services::Middleware.logger.warn(
            'Hoodoo::Services::Session\#save_to_memcached: Session saving failed - connection fault or session corrupt',
            exception.to_s
          )

        end

        return :fail
      end

      # Load session data into this instance, overwriting instance values
      # if the session is found. Raises an exception if there is a problem
      # connecting to Memcached. A Memcached connection host must have been
      # set through the constructor or #memcached_host accessor first.
      #
      # +sid+:: The Session UUID to look up.
      #
      # Returns a symbol:
      #
      # * +:ok+: The session data was loaded OK and is valid.
      #
      # * +:outdated+: The session data was loaded, but is outdated; either
      #   the session has expired, or its Caller version mismatches the
      #   associated stored Caller version in Memcached.
      #
      # * +:not_found+: The session was not found.
      #
      # * +:fail+: The session data could not be loaded (Memcached problem).
      #
      def load_from_memcached!( sid )
        begin
          mclient      = self.class.connect_to_memcached( self.memcached_host() )
          session_hash = mclient.get( sid )

          if session_hash.nil?
            return :not_found
          else
            self.from_h!( session_hash )
            return :outdated if self.expired?

            cv = load_caller_version_from_memcached( mclient, self.caller_id )

            if cv == nil || cv > self.caller_version
              return :outdated
            else
              return :ok
            end
          end

        rescue => exception

          # Log error and return nil if the session can't be parsed
          #
          Hoodoo::Services::Middleware.logger.warn(
            'Hoodoo::Services::Session\#load_from_memcached!: Session loading failed - connection fault or session corrupt',
            exception.to_s
          )

        end

        return :fail
      end

      # Update the version of a given Caller in Memcached. This is done
      # automatically when Sessions are saved to Memcached, but if external
      # code alters any Callers independently, it *MUST* call here to keep
      # Memcached records up to date.
      #
      # If no cached version is in Memcached for the Caller, the method
      # assumes it is being called for the first time for that Caller and
      # writes the version it has to hand, rather than considering it an
      # error condition.
      #
      # +cid+::     Caller UUID of the Caller record to update.
      #
      # +cv+::      New version to store (an Integer).
      #
      # +mclient+:: Optional Dalli::Client instance to use for talking to
      #             Memcached. If omitted, a connection is established for
      #             you. This is mostly an optimisation parameter, used by
      #             code which already has established a connection and
      #             wants to avoid creating another unnecessarily.
      #
      # Returns a Symbol:
      #
      # * +:ok+: The Caller record was updated successfully.
      #
      # * +:outdated+: The Caller was already present in Memcached with a
      #   _higher version_ than the one you wanted to save. Your own local
      #   Caller data must therefore already be out of date.
      #
      # * +:fail+: The Caller could not be updated (Memcached problem).
      #
      def update_caller_version_in_memcached( cid, cv, mclient = nil )
        begin
          mclient ||= self.class.connect_to_memcached( self.memcached_host() )

          cached_version = load_caller_version_from_memcached( mclient, cid )

          if cached_version != nil && cached_version > cv
            return :outdated
          elsif save_caller_version_to_memcached( mclient, cid, cv ) == true
            return :ok
          end

        rescue => exception

          # Log error and return nil if the session can't be parsed
          #
          Hoodoo::Services::Middleware.logger.warn(
            'Hoodoo::Services::Session\#update_caller_version_in_memcached: Client version update - connection fault or corrupt record',
            exception.to_s
          )

        end

        return :fail
      end

      # Delete this session from Memcached. The Session object is not
      # modified.
      #
      # Returns a symbol:
      #
      # * +:ok+: The Session was deleted from Memcached successfully.
      #
      # * +:not_found+: This session was not found in Memcached.
      #
      # * +:fail+: The session data could not be deleted (Memcached problem).
      #
      def delete_from_memcached
        begin

          mclient = self.class.connect_to_memcached( self.memcached_host() )

          if mclient.delete( self.session_id )
            return :ok
          else
            return :not_found
          end

        rescue => exception

          # Log error and return nil if the session can't be parsed
          #
          Hoodoo::Services::Middleware.logger.warn(
            'Hoodoo::Services::Session\#delete_from_memcached: Session delete - connection fault',
            exception.to_s
          )

          return :fail
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

        return ! ( exp.nil? || now < exp )
      end

      # Represent this session's data as a Hash, for uses such as
      # storage in Memcached or loading into another session instance.
      # See also #from_h!.
      #
      def to_h
        hash = {}

        %w(

          session_id
          caller_id
          caller_version

        ).each do | property |
          value = self.send( property )
          hash[ property ] = value unless value.nil?
        end

        %w(

          created_at
          expires_at

        ).each do | property |
          value = self.send( property )
          hash[ property ] = value.iso8601() unless value.nil?
        end

        %w(

          identity
          scoping
          permissions

        ).each do | property |
          value = self.send( property )
          hash[ property ] = Hoodoo::Utilities.stringify( value.to_h() ) unless value.nil?
        end

        return hash
      end

      # Load session parameters from a given Hash, of the form set by
      # #to_h.
      #
      # If appropriate Hash keys are present, will set any or all of
      # #session_id, #identity, #scoping and #permissions.
      #
      def from_h!( hash )
        hash = Hoodoo::Utilities.stringify( hash )

        %w(

          session_id
          caller_id
          caller_version

        ).each do | property |
          value = hash[ property ]
          self.send( "#{ property }=", value ) unless value.nil?
        end

        %w(

          created_at
          expires_at

        ).each do | property |
          if hash.has_key?( property )
            begin
              instance_variable_set( "@#{ property }", Time.parse( hash[ property ] ).utc() )
            rescue => e
              # Invalid time given; keep existing date
            end
          end
        end

        %w(

          identity
          scoping

        ).each do | property |
          value = hash[ property ]
          self.send( "#{ property }=", OpenStruct.new( value ) ) unless value.nil?
        end

        value = hash[ 'permissions' ]
        self.permissions = Hoodoo::Services::Permissions.new( value ) unless value.nil?
      end

      # Speciality interface usually only called by the middleware, or
      # components closely related to the middleware.
      #
      # Takes this session and creates a copy for an inter-resource call
      # which adds any additional parameters that the calling interface
      # says it needs in order to complete the currently handled action.
      #
      # Through calling this method, the middleware implements the access
      # permission functionality described by
      # Hoodoo::Services::Interface#additional_permissions_for.
      #
      # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
      #                 describing the current interaction. This is for the
      #                 request that a resource implementation *is handling*
      #                 at the point it wants to make an inter-resource call
      #                 - it is *not* data related to the *target* of that
      #                 call.
      #
      # Returns:
      #
      # * Hoodoo::Services::Session instance if everything works OK; this
      #   may be the same as, or different from, the input session depending
      #   on whether or not there were any permissions that needed adding.
      #
      # * +false+ if the session can't be saved due to a mismatched caller
      #   version - the session must have become invalid _during_ handling.
      #
      # If the augmented session cannot be saved due to a Memcached problem,
      # an exception is raised and the generic handler will turn this into a
      # 500 response for the caller. At this time, we really can't do much
      # better than that since failure to save the augmented session means
      # the inter-resource call cannot proceed; it's an internal fault.
      #
      def augment_with_permissions_for( interaction )

        # Set up some convenience variables

        interface = interaction.target_interface
        action    = interaction.requested_action

        # If there are no additional permissions for this action, just return
        # the current session back again.

        action                 = action.to_s()
        additional_permissions = ( interface.additional_permissions() || {} )[ action ]

        return self if additional_permissions.nil?

        # Otherwise, duplicate the session and its permissions (or generate
        # defaults) and merge the additional permissions.

        local_session     = self.dup()
        local_permissions = self.permissions ? self.permissions.dup() : Hoodoo::Services::Permissions.new

        local_permissions.merge!( additional_permissions.to_h() )

        # Make sure the new session has its own ID and set the updated
        # permissions. Then try to save it and return the result.

        local_session.session_id  = Hoodoo::UUID.generate()
        local_session.permissions = local_permissions

        case local_session.save_to_memcached()
          when :ok
            return local_session

          when :outdated
            # Caller version mismatch; original session is now outdated and invalid
            return false

          else # Couldn't save it
            raise "Unable to create interim session for inter-resource call from #{ interface.resource } / #{ action }"
        end
      end

    private

      # Connect to the Memcached server. Returns a new Dalli client
      # instance. Raises an exception if no connection can be established.
      #
      # In test environments, returns a MockDalliClient instance.
      #
      # +host+:: Connection host (IP "address:port" String) for Memcached.
      #
      def self.connect_to_memcached( host )

        if Hoodoo::Services::Middleware.environment.test? && MockDalliClient.bypass? == false
          return MockDalliClient.new
        end

        if host.nil? || host.empty?
          raise 'Hoodoo::Services::Session.connect_to_memcached: The Memcached connection host data is nil or empty'
        end

        exception = nil
        stats     = nil
        mclient   = nil

        begin
          @@dalli_clients         ||= {}
          @@dalli_clients[ host ] ||= ::Dalli::Client.new(
            host,
            {
              :compress   => false,
              :serializer => JSON,
              :namespace  => :nz_co_loyalty_hoodoo_session_
            }
          )

          stats = @@dalli_clients[ host ].stats()

        rescue => e
          exception = e

        end

        if stats.nil?
          if exception.nil?
            raise "Hoodoo::Services::Session.connect_to_memcached: Did not get back meaningful data from Memcached at '#{ host }'"
          else
            raise "Hoodoo::Services::Session.connect_to_memcached: Cannot connect to Memcached at '#{ host }': #{ exception.to_s }"
          end
        else
          return @@dalli_clients[ host ]
        end
      end

      # Try to read a cached Caller version from Memcached. Returns the
      # cached version if available, or +nil+ if the record isn't found.
      #
      # May raise an exception for e.g. Memcached failures, via Dalli.
      #
      # TODO: As a temporary measure, compatibility bridge code in Authsome
      #       may call this private interface via ".send". Until that is
      #       decommissioned, the API shouldn't be changed without updating
      #       Authsome too.
      #
      # +mclient+:: A Dalli::Client instance to use for talking to
      #             Memcached.
      #
      # +cid+::     Caller UUID of interest.
      #
      def load_caller_version_from_memcached( mclient, cid )
        version_hash = mclient.get( cid )
        return version_hash.nil? ? nil : version_hash[ 'version' ]
      end

      # Save the Caller version for a given Caller ID to Memcached.
      # Returns +true+ if successful, else +false+.
      #
      # May raise an exception for e.g. Memcached failures, via Dalli.
      #
      # Note that any existing record for the given Caller, if there
      # is one, is unconditionally overwritten.
      #
      # +mclient+:: A Dalli::Client instance to use for talking to
      #             Memcached.
      #
      # +cid+::     Caller UUID of interest.
      #
      # +cv+::      Version to save for that Caller UUID.
      #
      def save_caller_version_to_memcached( mclient, cid, cv )
        return !! mclient.set(
          cid,
          { 'version' => cv }
        )
      end

      # Mock known uses of Dalli::Client with test implementations.
      # Use explicitly, or as an RSpec implicit mock via something like
      # this:
      #
      #     allow( Dalli::Client ).to receive( :new ).and_return( Hoodoo::Services::Session::MockDalliClient.new )
      #
      # ...whenever you need to stub out real Memcached. You will
      # probably want to add:
      #
      #     before :all do # (or ":each")
      #       Hoodoo::Services::Session::MockDalliClient.reset()
      #     end
      #
      # ...to "clean out Memcached" before or between tests. You can
      # check the contents of mock Memcached by examining ::store's
      # hash of data.
      #
      class MockDalliClient
        @@store = {}

        # For test analysis, return the hash of 'memcached' mock data.
        #
        # Entries are referenced by the key you used to originally
        # store them; values are hashes with ":expires_at" giving an
        # expiry time or "nil" and ":value" giving your stored value.
        #
        def self.store
          @@store
        end

        # Wipe out all saved data.
        #
        def self.reset
          @@store = {}
        end

        # Pass +true+ to bypass the mock client (subject to the caller
        # reading ::bypass?) to e.g. get test code coverage on real
        # Memcached. Pass +false+ otherwise.
        #
        def self.bypass( bypass_boolean )
          @@bypass = bypass_boolean
        end

        @@bypass = false

        # If +true+, bypass this class and use real Dalli::Client; else
        # don't. Default return value is +false+.
        #
        def self.bypass?
          @@bypass
        end

        # Get the data stored under the given key. Returns +nil+ if
        # not found / expired.
        #
        # +key+:: Key to look up (see #set).
        #
        def get( key )
          data = @@store[ key ]
          return nil if data.nil?

          expires_at = data[ :expires_at ]
          return nil unless expires_at.nil? || Time.now < expires_at

          return data[ :value ]
        end

        # Set data for a given key.
        #
        # +key+::   Key under which to store data.
        #
        # +value+:: Data to store.
        #
        # +ttl+::   (Optional) time-to-live ('live' as in living, not as in
        #           'live TV') - a value in seconds, after which the data is
        #           considered expired. If omitted, the data does not expire.
        #
        def set( key, value, ttl = nil )
          data = {
            :expires_at => ttl.nil? ? nil : Time.now.utc + ttl,
            :value      => value
          }

          @@store[ key ] = data
          true
        end

        # Remove data for the given key.
        #
        def delete( key )
          if @@store.has_key?( key )
            @@store.delete( key )
            true
          else
            false
          end
        end

        # Mock 'stats' health check.
        #
        def stats
          true
        end
      end
    end
  end
end
