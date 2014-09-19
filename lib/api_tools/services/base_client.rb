module ApiTools
  module Services
    class BaseClient < AQMPEndpoint

      def initialize(amqp_uri, options = {})
        super amqp_uri, options
        @response_endpoint = "client.#{@endpoint_id}"
      end

    end
  end
end