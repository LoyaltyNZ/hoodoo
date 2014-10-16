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

  # A description of the authorised context in which a service is called.
  #
  class ServiceSession
    attr_reader :id, :participant_id, :outlet_id

    @@test_mode = false

    @@test_session = {
        :id => '0123456789ABCDEF',
        :participant_id => 'PARTICIPANTZERO',
        :outlet_id => 'OUTLETZERO',
        :roles => [],
      }


    # Set testing mode. 
    #
    # The optional +mock_session+ parameter will 
    def self.testing(test_mode, mock_session = nil)
      @@test_mode = test_mode
      @@test_session = mock_session unless mock_session.nil?
    end

    def self.load_session(memcache_url, session_id)
      
      return ApiTools::ServiceSession.new(@@test_session) if @@test_mode

      # Connect to the Memcache Session Server
      raise "ApiTools::ServiceMiddleware not supplied MEMCACHE_URL in ENV." if memcache_url.nil? || memcache_url.empty?
      
      @memcache = Dalli::Client.new(memcache_url, {:compress=>true})
      stats = nil
      begin
        stats = @memcache.stats
      rescue Exception => e
        stats = nil
      end
      raise "ApiTools::ServiceMiddleware cannot connect to memcache server." if stats.nil?

      if session_id.nil? or session_id.empty? or session_id.length<32
        return @service_response.add_error('platform.invalid_session')
      end

      session_hash = @memcache.get("session_"+session_id)
      return @service_response.add_error('platform.invalid_session') if session_hash.nil?

      begin
        session_hash = JSON.parse(session_hash)
      rescue Exception => exception
        log(:warning, "Session loaded but failed JSON parsing", exception)
        return @service_response.add_error('platform.invalid_session')
      end

      return ApiTools::ServiceSession.new({
        :id => session_id,
        :participant_id => session_hash['participant_id'],
        :outlet_id => session_hash['outlet_id'],
        :roles => session_hash['roles'],
      })
    end

    def initialize(options = {})
      @id = options[:id]
      @participant_id = options[:participant_id]
      @outlet_id = options[:outlet_id]
      @roles = options[:roles]
    end

    def has_role?(role)
      @roles.include? role.to_s
    end
  end
end
