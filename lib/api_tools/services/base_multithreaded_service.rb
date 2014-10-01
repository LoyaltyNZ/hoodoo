module ApiTools
  module Services
    class BaseMultithreadedService < AQMPMultithreadedEndpoint

      def initialize(amqp_uri, name, options = {})
        super amqp_uri, options
        @request_endpoint = "#{name}"
        @response_endpoint = "#{name}.#{@endpoint_id}"
        @queue_options = options[:queue_options] || {:exclusive => false, :auto_delete => false}
      end

      def send_message(msg)
        msg.reply_to = @response_endpoint
        @tx_queue << msg
      end
    end

  end
end
