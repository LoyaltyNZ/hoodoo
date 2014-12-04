########################################################################
# File::    service_session.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Container for information about the context in which a
#           service is called.
# ----------------------------------------------------------------------
#           03-Oct-2014 (ADH): Created.
#           16-Oct-2014 (TC): Implemented Basic Functionality.
########################################################################

require 'dalli'

module ApiTools

  # +ServiceSession+ contains all functionality related to a context session.
  #
  class ServiceSession

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
      :roles          => '',
    }

    # Set testing mode.
    #
    # +test_mode+ should be set to true/false. The optional +mock_session+ parameter
    # defines the test session supplied.
    def self.testing(test_mode, mock_session = nil)
      @@test_mode = test_mode
      @@test_session = mock_session unless mock_session.nil?
    end

    # Create a ServiceSession instance by loading the session from memcache.
    #
    # The +memcache_url+ parameter should be set to the session memcache server, the
    # +session_id+ parameter is the ID of the session to load. The method will return
    # either a valid ServiceSession instance, or nil if the session does not exist or is
    # invalid.
    def self.load_session(memcache_url, session_id)

      return ApiTools::ServiceSession.new(@@test_session) if @@test_mode

      # Check that ENV[MEMCACHE_URL] exists.
      raise "ApiTools::ServiceMiddleware memcache server URL is nil or empty" if memcache_url.nil? || memcache_url.empty?

      # Return nil if the session_id is nil, empty or less than 32 chars long.
      if session_id.nil? or session_id.empty? or session_id.length<32
        return nil
      end

      # Connect to memcache, raise an error if we cant
      memcache = connect_memcache(memcache_url)
      raise "ApiTools::ServiceMiddleware cannot connect to memcache server '#{memcache_url}'" if memcache.nil?

      begin
        # Get The session from the server
        session_hash = memcache.get("session_"+session_id)
        # Return nil if the session can't be found
        return nil if session_hash.nil?
      rescue Exception => exception
        # Log error and Return nil if the session can't be parsed
        ApiTools::Logger.warn("Session Loading failed, connection fault or session corrupt", exception)
        return nil
      end

      # Create and return the new session.
      return ApiTools::ServiceSession.new({
        :id             => session_id,
        :client_id      => session_hash[ 'client_id'      ],
        :participant_id => session_hash[ 'participant_id' ],
        :outlet_id      => session_hash[ 'outlet_id'      ],
        :roles          => session_hash[ 'roles'          ],
      })
    end

    # Instantiate a new ServiceSession instance with the optional supplied
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
      return true if @@test_mode && @roles.length == 0 
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

    # Connect to the Memcache Session Server
    def self.connect_memcache(url)
      stats = nil
      begin
        memcache = Dalli::Client.new(url, { :compress=>false, :serializer => JSON })
        stats = memcache.stats
      rescue Exception => e
        stats = nil
      end
      stats.nil? ? nil : memcache
    end
  end
end
