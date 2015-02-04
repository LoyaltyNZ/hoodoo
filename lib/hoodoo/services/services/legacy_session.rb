########################################################################
# File::    session.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Container for information about the context in which a
#           service is called.
# ----------------------------------------------------------------------
#           03-Oct-2014 (ADH): Created.
#           16-Oct-2014 (TC): Implemented Basic Functionality.
########################################################################

require 'dalli'

module Hoodoo; module Services

  # +Session+ contains all functionality related to a context session.
  #
  class Session

    # Session ID, matching a value that would appear in an X-Session-ID
    # header.
    #
    attr_reader :id

    # TODO: Loyalty NZ specific. The ID of the calling client, as defined
    # in the authorisation application.
    #
    attr_reader :client_id

    # TODO: Loyalty NZ specific. The UUID of the Participant instance
    # associated with the authorised caller.
    #
    attr_reader :participant_id

    # TODO: Loyalty NZ specific. The UUID of the Outlet instance associated
    # with the authorised caller, related to #participant_id.
    #
    attr_reader :outlet_id

    # TODO: Loyalty NZ derived, needs better specification. Array of strings
    # describing roles. Role meanings are defined by role usage within
    # services.
    #
    attr_reader :roles

    @@test_mode    = false
    @@test_session = {
      :id             => '0123456789ABCDEF',
      :client_id      => 'ABCDEF0123456789',
      :participant_id => 'e9421091be4d45419ed67326392ee641',
      :outlet_id      => '30c13f64e1044026b350b77c9b4aa6aa',
      :roles          => ENV[ 'HOODOO_TEST_SESSION_ROLES' ] || '',
    }

    # TODO: Loyalty NZ derived, needs better specification.
    #
    # Set testing mode.
    #
    # +test_mode+::    +true+ to use a static mock test session, +false+ to
    #                  read real session data from Memcached based on inbound
    #                  requests' X-Session-ID header values.
    #
    # +mock_session+:: Optional mock session to use, overriding internal test
    #                  mock session. The internal static test session has no
    #                  roles assigned, but will read a string of
    #                  comma-separated roles from
    #                  +ENV[ 'HOODOO_TEST_SESSION_ROLES' ]+ if defined.
    #
    def self.testing(test_mode, mock_session = nil)
      @@test_mode = test_mode
      @@test_session = mock_session unless mock_session.nil?
    end

    # TODO: Loyalty NZ derived, needs better specification.
    #
    # Create a Session instance by loading session data from Memcached,
    # or a test mock session if in test mode (see ::testing).
    #
    # +memcache_url+:: Connection URL for Memcached.
    # +session_id+::   ID of the session to load.
    #
    # Returns either a valid Session instance, or +nil+ if the session
    # does not exist or is invalid.
    #
    def self.load_session( memcache_url, session_id )

      return Hoodoo::Services::Session.new( @@test_session ) if @@test_mode

      if memcache_url.nil? || memcache_url.empty?
        raise "Hoodoo::Services::Middleware memcache server URL is nil or empty"
      end

      if session_id.nil? || session_id.empty? || session_id.length < 32
        return nil
      end

      memcache = connect_memcache( memcache_url )

      if memcache.nil?
        raise "Hoodoo::Services::Middleware cannot connect to memcache server '#{memcache_url}'"
      end

      begin

        session_hash = memcache.get( "session_#{ session_id }" )
        return nil if session_hash.nil?

      rescue Exception => exception

        # Log error and return nil if the session can't be parsed
        #
        Hoodoo::Services::Middleware.logger.warn(
          "Session Loading failed, connection fault or session corrupt",
          exception
        )

        return nil

      end

      # Create and return the new session.
      #
      return Hoodoo::Services::Session.new( {
        :id             => session_id,
        :client_id      => session_hash[ 'client_id'      ],
        :participant_id => session_hash[ 'participant_id' ],
        :outlet_id      => session_hash[ 'outlet_id'      ],
        :roles          => session_hash[ 'roles'          ],
      } )
    end

    # Instantiate a new Session instance with the optional supplied
    # parameters.
    #
    # +options+:: Optional hash of parameters.
    #
    # Key/value meanings for options are:
    #
    # +id+::             Session ID, e.g. from an X-Session-ID header.
    # +client_id+::      TODO: LoyaltyNZ specific. ID of API-calling client,
    #                    according to OAuth authorisation application.
    # +participant_id+:: TODO: LoyaltyNZ specific. Participant UUID associated
    #                    with this session.
    # +outlet_id+::      TODO: LoyaltyNZ specific. Outlet UUID associated with
    #                    the participant.
    # +roles+::          TODO: Role string, containing comma-separated roles
    #                    that get split into an Array. Role meanings are
    #                    defined by role usage within services.
    #
    def initialize(options = {})

      @id             = options[ :id             ]
      @client_id      = options[ :client_id      ]
      @participant_id = options[ :participant_id ]
      @outlet_id      = options[ :outlet_id      ]
      @roles          = options[ :roles          ].to_s.split( ',' )

      @to_h = {
        :id             => @id,
        :client_id      => @client_id,
        :participant_id => @participant_id,
        :outlet_id      => @outlet_id,
        :roles          => @roles
      }

    end

    # Returns true if this session has the specified role
    def has_role?(role)
      @roles.include? role.to_s
    end

    # Returns true if this session has all specified roles
    def has_all_roles?(roles)
      (@roles & roles).length == roles.length
    end

    # Returns true if this session has any of the specified roles
    def has_any_roles?(roles)
      (@roles & roles).length > 0
    end

    # Returns a representation of the Session data as a Hash.
    #
    # TODO: LoyaltyNZ specific - hash matches input options in #initialize,
    #       but with role string split into an Array.
    #
    def to_h
      @to_h
    end

    private

    # Connect to the Memcached server.
    #
    # +url+:: Connection URL for Memcached.
    #
    def self.connect_memcache( url )
      stats = nil

      begin
        memcache = Dalli::Client.new(
          url,
          { :compress=>false, :serializer => JSON }
        )

        stats = memcache.stats

      rescue Exception => e
        stats = nil

      end

      stats.nil? ? nil : memcache
    end
  end

end; end
