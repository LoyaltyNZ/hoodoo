require 'resolv'
require 'dalli'
require 'openssl'
require 'base64'
require 'json'
require "net/http"
require "uri"

module ApiTools
  module Auth

    #
    # Needs:
    # CONFIG['auth'] => {
    #   'auth_service_uri' => 'http://auth.service.consul',
    #   'session_secret' => 'q87324f9cns8ebc7qg3dh',
    #   'consul_dns_nameservers' => [ 'localhost' ],
    #   'memcache_host_name' => 'memcache.service.consul'
    # }
    class PlatformAuth
      def self.get_session(session_id)
        addresses = get_memcache_addresses
        return nil if session_data.count < 1

        memcache = Dalli::Client.new(addresses[0]+':11211', { :namespace => 'sessions_'})
        return nil if memcache.nil?

        session_data = memcache.get(session_id)
        return nil if session_data.nil?
      
        session_data = parse_hmac(session_data, CONFIG['auth']['session_secret'])
        return nil if session_data.nil?

        touch_session(session_id)

        JSON.parse(session_data)
      end

      # Touch the supplied session by calling touch on the configured Auth Service 
      # (CONFIG['auth']['auth_service_uri']+"/session/current/touch")
      def self.touch_session(session_id)
        uri = URI.parse(CONFIG['auth']['auth_service_uri']+"/session/current/touch")
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Post.new uri.request_uri
        request['X-Session-Id'] = session_id

        response = http.request(request)

        unless !response.code.nil? && response.code.to_i >= 200 and response.code.to_i <= 400
          ApiTools::Logger.error("ApiTools::Auth::PlatformAuth received HTTP Error #{response.code} #{response.message} from Auth Service #{uri} with #{response.body}")
        end
      end

      private

      def self.get_memcache_addresses
        client = Resolv::DNS.new({
          :nameserver => CONFIG['auth']['consul_dns_nameservers']
        })

        client.get_addresses(CONFIG['auth']['memcache_host_name']).map { |ip4addr| ip4addr.address }
      end

      def self.parse_hmac(data, key)
        data = data.split(':')
        return nil unless data.count == 2
        return nil unless OpenSSL::HMAC('sha1', key, data[0]) == data[1]
        Base64.decode64(data[1]) 
      end
    end
  end
end