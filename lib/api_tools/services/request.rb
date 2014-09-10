module ApiTools
  module Services
    class Request < ApiTools::Services::AMQPMessage

      attr_accessor :is_async
      attr_reader :queue

      def initialize(exchange, options)
        super exchange, options
        @queue = Queue.new
      end

      def create_response(options = {})
        c_options = {
          :request => self,
          :correlation_id => @message_id,
          :type => 'response',
        }
        c_options.merge!(options)
        ApiTools::Services::Response.new(exchange, c_options)
      end

      def is_async?
        @is_async
      end
    end
  end
end