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
    attr_reader :id, :participant_id, :outlet_id, :roles

    @@test_mode = false

    @@test_session = {
      :id => '0123456789ABCDEF',
      :participant_id => 'PARTICIPANTZERO',
      :outlet_id => 'OUTLETZERO',
      :roles => '',
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

      # Get The session from the server
      session_hash = memcache.get("session_"+session_id)
      # Return nil if the session can't be found
      return nil if session_hash.nil?

      # Parse the session
      begin
        session_hash = JSON.parse(session_hash)
      rescue Exception => exception
        # Log error and Return nil if the session can't be parsed
        ApiTools::Logger.warn("Session loaded but failed JSON parsing", exception)
        return nil
      end

      # Create and return the new session.
      return ApiTools::ServiceSession.new({
        :id => session_id,
        :participant_id => session_hash['participant_id'],
        :outlet_id => session_hash['outlet_id'],
        :roles => session_hash['roles'],
      })
    end

    # Instantiate a new ServiceSession instance with the optional supplied parameters
    #
    def initialize(options = {})
      @id = options[:id]
      @participant_id = options[:participant_id]
      @outlet_id = options[:outlet_id]
      @roles = options[:roles].to_s.split ','
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

    private

    # Connect to the Memcache Session Server
    def self.connect_memcache(url)
      stats = nil
      begin
        memcache = Dalli::Client.new(url, { :compress=>true, :serializer => JSON })
        stats = memcache.stats
      rescue Exception => e
        stats = nil
      end
      stats.nil? ? nil : memcache
    end
  end
end
