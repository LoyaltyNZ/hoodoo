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
require 'hoodoo/transient_store'

module Hoodoo
  module Services

    # A container for functionality related to a context session.
    #
    class Session

      # Time To Live: Number of seconds for which a session remains valid
      # after being saved.
      #
      TTL = 172800 # 48 hours

      # A Session must have its own UUID.
      #
      attr_accessor :session_id

      # A Session must always refer to a Caller instance by UUID.
      #
      attr_accessor :caller_id

      # An optional property of a session is the Caller's "identity name",
      # a generic way to refer to this Caller which will appear in logs.
      # The use is up to the session creator, in combination with whatever
      # logging engine is in use; if it ascribes meaning to the identity
      # name, then the session creator must ensure it comforms.
      #
      attr_accessor :caller_identity_name

      # An optional property of a session is the Caller's fingerprint, a
      # UUID assigned to some Callers which can be persisted by resource
      # instances when created and rendered in the +created_by+ field
      # via e.g. Hoodoo::Presenters::Base.#render_in.
      #
      attr_accessor :caller_fingerprint

      # Callers can change; if so, related sessions must be invalidated.
      # This must be achieved by keeping a version count on the Caller. A
      # session is associated with a particular Caller version and if the
      # version changes, associated sessions are flushed.
      #
      # If you _change_ a Caller version in a Session, you _really_ should
      # call #save_to_store as soon as possible afterwards so that the
      # change gets recognised in the transient store.
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
      # * #save_to_store
      #
      # The value is a Time instance in UTC. If +nil+, the session has not
      # yet been saved.
      #
      attr_reader :expires_at

      # Transient store configuration
      #
      # Symbolised key describing the type of name/engine used.
      #
      # Supported names include:
      #   - :memcached (default if no argument provided)
      #   - :redis
      #   - :memcached_redis_mirror
      #
      attr_accessor :transient_store_name

      # Host configuration for selected transient engine
      #
      # Connection IP address/port String for the selected transient engine.
      #
      # If you are using Memcached or Redis as a session store, you can set the
      # connection host either through this accessor, or via the
      # object's constructor.
      attr_accessor :transient_store_host

      # Create a new instance.
      #
      # +options+:: Optional Hash of options, described below.
      #
      # Options are:
      #
      # +session_id+::            UUID of this session. If unset, a new UUID is
      #                           generated for you. You can read the UUID with
      #                           the #session_id accessor method.
      #
      # +caller_id+::             UUID of the Caller instance associated with this
      #                           session. This can be set either now or later, but
      #                           the session cannot be saved without it.
      #
      # +caller_version+::        Version of the Caller instance. Defaults to zero.
      #
      # +caller_fingerprint::     Optional Caller fingerprint UUID. Defaults to
      #                           +nil+.
      #
      # +transient_store_name+::  Name for the transient storage engine.
      #                           Supported names include:
      #                             +:memcached+ (default)
      #                             +:redis+
      #                             +:memcached_redis_mirror+
      #
      # +transient_store_host+::  Host for transient storage engine connections.
      #
      # +memcached_host+::        Host for Memcached connections (deprecated).
      #
      def initialize( options = {} )
        @created_at = Time.now.utc

        self.session_id             = options[ :session_id            ] || Hoodoo::UUID.generate()
        self.transient_store_name   = options[ :transient_store_name  ] || :memcached
        self.transient_store_host   = options[ :transient_store_host  ] || options[ :memcached_host ]
        self.caller_id              = options[ :caller_id             ]
        self.caller_version         = options[ :caller_version        ] || 0
        self.caller_fingerprint     = options[ :caller_fingerprint    ]
      end

      # Save this session to the transient store, in a manner that will allow
      # it to be loaded by #load_from_store! later.
      #
      # A session can only be saved if it has a Caller ID - see #caller_id= or
      # the options hash passed to the constructor.
      #
      # The Hoodoo::Services::Session::TTL constant determines the maximum
      # length of time for which the data persists inside the transient store.
      #
      # Returns a symbol:
      #
      # * +:ok+: The session data was saved OK and is valid. There was either
      #   a Caller record with an earlier or matching value in the transient
      #   store, no preexisting record of the Caller.
      #
      # * +:outdated+: The session data could not be saved because an existing
      #   Caller record was found in the transient store with a _newer_ version
      #   than 'this' session, implying that the session is already outdated.
      #
      # * +:fail+: The session data could not be saved.
      #
      def save_to_store
        if self.caller_id.nil?
          raise 'Hoodoo::Services::Session\#save_to_store: Cannot save this session as it has no assigned Caller UUID'
        end

        begin
          store = get_store()

          # Try to update the Caller version in the store using this
          # Session's data. If this fails, the Caller version is out of
          # date or we couldn't talk to the store. Either way, bail out.
          #
          # TL;DR: The 'update' call here is critical.
          #
          # This process refreshes the caller version information in the
          # transient store back-end with each new Session. If eventually the
          # Caller version is expired or evicted, Sessions would be immediately
          # invalidated and a recreation would result in the Caller version
          # being rewritten.
          #
          # What if the Caller goes out of date? An external service must gate
          # access to Caller resource changes and update the Caller version
          # itself if the Caller alters in a way that should invalidate
          # Sessions. This refreshes the lifetime on that item which normally
          # expires at a much greater TTL than sessions anyway and, if anyone
          # tries to use a Stale session after, the Caller version mismatch
          # will invalidate it so they'll need a new one.
          #
          # If a Caller version is created but somehow evicted before any of
          # the older existing Sessions (perhaps because Caller version data is
          # small but Session data is large) then attempts to read the Session
          # will fail; *loading* a Session requires the Caller version. The
          # Caller would have to create a new Session and this would by virtue
          # of the handling resource endpoint's service code acquire the new
          # Caller version data immediately then cause it to be re-asserted /
          # re-written by the code below.
          #
          result = update_caller_version_in_store( self.caller_id,
                                                   self.caller_version,
                                                   store )

          return result unless result.equal?( :ok )

          # Must set this before saving, even though the delay between
          # setting this value and the store actually saving the value
          # with a TTL will mean that the store expires the key slightly
          # *after* the time we record.

          @expires_at = ( ::Time.now + TTL ).utc()
          result      = store.set( key:              self.session_id,
                                   payload:          self.to_h(),
                                   maximum_lifespan: TTL )

          case result
            when true
              return :ok
            when false
              raise 'Unknown storage engine failure'
            else
              raise result
          end

        rescue => exception

          # Log error and return nil if the session can't be parsed
          #
          Hoodoo::Services::Middleware.logger.warn(
            'Hoodoo::Services::Session\#save_to_store: Session saving failed - connection fault or session corrupt',
            exception.to_s
          )

        end

        return :fail
      end

      # Deprecated alias for #save_to_store, dating back to when the Session
      # engine was hard-coded to Memcached.
      #
      alias_method( :save_to_memcached, :save_to_store )

      # Load session data into this instance, overwriting instance values
      # if the session is found. Raises an exception if there is a problem
      # connecting to the transient store.
      #
      # +sid+:: The Session UUID to look up.
      #
      # Returns a symbol:
      #
      # * +:ok+: The session data was loaded OK and is valid.
      #
      # * +:outdated+: The session data was loaded, but is outdated; either
      #   the session has expired, or its Caller version mismatches the
      #   associated stored Caller version in the transient store.
      #
      # * +:not_found+: The session was not found.
      #
      # * +:fail+: The session data could not be loaded (unexpected storage
      #            engine failure).
      #
      def load_from_store!( sid )
        begin
          store        = get_store()
          session_hash = store.get( key: sid, allow_throw: true )

          if session_hash.nil?
            return :not_found
          else
            self.from_h!( session_hash )
            return :outdated if self.expired?

            cv = load_caller_version_from_store( store, self.caller_id )

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
            'Hoodoo::Services::Session\#load_from_store!: Session loading failed - connection fault or session corrupt',
            exception.to_s
          )

        end

        return :fail
      end

      # Deprecated alias for #load_from_store!, dating back to when the Session
      # engine was hard-coded to Memcached.
      #
      alias_method( :load_from_memcached!, :load_from_store! )

      # Update the version of a given Caller in the transient store. This is
      # done automatically when Sessions are saved to that store, but if
      # external code alters any Callers independently, it *MUST* call here to
      # keep stored records up to date.
      #
      # If no cached version is in the transient store for the Caller, the
      # method assumes it is being called for the first time for that Caller
      # and writes the version it has to hand, rather than considering it an
      # error condition.
      #
      # +cid+::   Caller UUID of the Caller record to update.
      #
      # +cv+::    New version to store (an Integer).
      #
      # +store+:: Optional Hoodoo::TransientStore instance to use for data
      #           storage. If omitted, a connection is established for
      #           you. This is mostly an optimisation parameter, used by
      #           code which already has established a connection and
      #           wants to avoid creating another unnecessarily.
      #
      # Returns a Symbol:
      #
      # * +:ok+: The Caller record was updated successfully.
      #
      # * +:outdated+: The Caller was already present in the transient store
      #   with a _higher version_ than the one you wanted to save. Your own
      #   local Caller data must therefore already be out of date.
      #
      # * +:fail+: The Caller could not be updated (unexpected storage engine
      #            failure).
      #
      def update_caller_version_in_store( cid, cv, store = nil )
        begin
          store        ||= get_store()
          cached_version = load_caller_version_from_store( store, cid )

          if cached_version != nil && cached_version > cv
            return :outdated
          elsif save_caller_version_to_store( store, cid, cv ) == true
            return :ok
          end

        rescue => exception

          # Log error and return nil if the session can't be parsed
          #
          Hoodoo::Services::Middleware.logger.warn(
            'Hoodoo::Services::Session\#update_caller_version_in_store: Client version update - connection fault or corrupt record',
            exception.to_s
          )

        end

        return :fail
      end

      # Deprecated 'get' interface (use #transient_store_host instead),
      # dating back to when the Session engine was hard-coded to Memcached.
      #
      # Supports backwards compatibility of options key +memcached_host+,
      # aliases +transient_store_host+.
      #
      # Provides same functionality as #alias_method, however includes a deprecation
      # warning
      #
      # Similar to:
      # alias_method :memcached_host, :transient_store_host
      #
      def memcached_host( *args, &block )
        Hoodoo::Services::Middleware.logger.warn(
          'Hoodoo::Services::Session#memcached_host is deprecated - use #transient_store_host'
        )

        self.send( :transient_store_host, *args, &block )
      end

      # Deprecated 'set' interface (use #transient_store_host= instead),
      # dating back to when the Session engine was hard-coded to Memcached.
      #
      # Similar to:
      # alias_method :memcached_host=, :transient_store_host=
      #
      def memcached_host=( *args, &block )
        Hoodoo::Services::Middleware.logger.warn(
          'Hoodoo::Services::Session#memcached_host= is deprecated - use #transient_store_host='
        )

        self.send( :transient_store_host=, *args, &block )
      end

      # Deprecated interface (use #update_caller_version_in_store instead),
      # dating back to when the Session engine was hard-coded to Memcached.
      #
      # Parameters as for #update_caller_version_in_store, except +store+ is
      # must be a fully configured Dalli::Client instance. Use of this
      # interface is inefficient and discouraged; it will result in logged
      # warnings.
      #
      def update_caller_version_in_memcached( cid, cv, store = nil )
        unless store.nil?
          Hoodoo::Services::Middleware.logger.warn(
            'Hoodoo::Services::Session#update_caller_version_in_memcached is deprecated - use #update_caller_version_in_store'
          )

          # Inefficient - create a TransientStore configured for the normal
          # Memcached connection data, but get hold of its storage engine and
          # change that engine's client to the provided Dalli::Client instance.

          temp_store = Hoodoo::TransientStore.new(
            storage_engine:    :memcached,
            storage_host_uri:  self.memcached_host(),
            default_namespace: 'nz_co_loyalty_hoodoo_session_'
          )

          memcached_engine        = temp_store.storage_engine_instance()
          memcached_engine.client = store

          begin
            update_caller_version_in_store( cid, cv, temp_store )
          ensure
            temp_store.close()
          end

        else
          update_caller_version_in_store( cid, cv )

        end
      end

      # Delete this session from the transient store. The Session object is not
      # modified.
      #
      # Returns a symbol:
      #
      # * +:ok+: The Session was deleted from the transient store successfully.
      #
      # * +:fail+: The session data could not be deleted (unexpected storage
      #            engine failure).
      #
      def delete_from_store
        begin

          store  = get_store()
          result = store.delete( key: self.session_id )

          case result
            when true
              return :ok
            when false
              raise 'Unknown storage engine failure'
            else
              raise result
          end

        rescue => exception

          # Log error and return nil if the session can't be parsed
          #
          Hoodoo::Services::Middleware.logger.warn(
            'Hoodoo::Services::Session\#delete_from_store: Session delete - connection fault',
            exception.to_s
          )

          return :fail
        end

      end

      # Deprecated alias for #delete_from_store, dating back to when the
      # Session engine was hard-coded to Memcached.
      #
      alias_method( :delete_from_memcached, :delete_from_store )

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

      # Represent this session's data as a Hash, for uses such as persistence
      # or loading into another session instance. See also #from_h!.
      #
      def to_h
        hash = {}

        %w(

          session_id
          caller_id
          caller_version
          caller_identity_name
          caller_fingerprint

        ).each do | property |
          value = self.send( property )
          hash[ property ] = value unless value.nil?
        end

        %w(

          created_at
          expires_at

        ).each do | property |
          value = self.send( property )
          hash[ property ] = Hoodoo::Utilities.standard_datetime( value ) unless value.nil?
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
          caller_identity_name
          caller_fingerprint

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
      # If the augmented session cannot be saved due to a storage problem,
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

        case local_session.save_to_store()
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

      # Connect to the storage engine, using the +transient_store_name+ and
      # +transient_store_host+ attributes. Returns a Hoodoo:TransientStore
      # instance. Raises an exception if no connection can be established.
      #
      def get_store
        engine = self.transient_store_name()
        host   = self.transient_store_host()
        begin
          @@stores         ||= {}
          @@stores[ host ] ||= Hoodoo::TransientStore.new(
            storage_engine:    engine,
            storage_host_uri:  host,
            default_namespace: 'nz_co_loyalty_hoodoo_session_'
          )

          raise 'Unknown storage engine failure' if @@stores[ host ].nil?

        rescue => exception
          raise "Hoodoo::Services::Session\#get_store: Cannot connect to #{ engine } at '#{ host }': #{ exception }"

        end

        @@stores[ host ]
      end

      # Try to read a cached Caller version from the transient store. Returns
      # the cached version if available, or +nil+ if the record isn't found.
      #
      # May raise an exception for e.g. unexpected storage engine failures.
      #
      # TODO: As a temporary measure, compatibility bridge code in Authsome
      #       may call this private interface via ".send". Until that is
      #       decommissioned, the API shouldn't be changed without updating
      #       Authsome too.
      #
      # +store+:: A Hoodoo::TransientStore instance to use for storage.
      # +cid+::   Caller UUID of interest.
      #
      def load_caller_version_from_store( store, cid )
        version_hash = store.get( key: cid, allow_throw: true )
        return version_hash.nil? ? nil : version_hash[ 'version' ]
      end

      # Save the Caller version for a given Caller ID to the transient store.
      # Returns +true+ if successful, else +false+.
      #
      # May raise an exception for e.g. unexpected storage engine failures.
      #
      # Note that any existing record for the given Caller, if there
      # is one, is unconditionally overwritten.
      #
      # +store+:: A Hoodoo::TransientStore instance to use for storage.
      # +cid+::   Caller UUID of interest.
      # +cv+::    Version to save for that Caller UUID.
      #
      def save_caller_version_to_store( store, cid, cv )
        result = store.set(
          key:     cid,
          payload: { 'version' => cv }
        )

        if result.is_a?( Exception )
          raise result
        else
          return result
        end
      end

      # Before Hoodoo::TransientStore was created, the Session system was
      # directly tied into Memcached and had a mock backend used for tests
      # without a Redis dependency. This now lives in
      # Hoodoo::TransientStore::Mocks::DalliClient, but for any code out in
      # the wild which might use the old Session namespace version, we add
      # what amounts to a class alias here.
      #
      MockDalliClient = Hoodoo::TransientStore::Mocks::DalliClient
    end
  end
end
