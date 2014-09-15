module ApiTools
  module Services
    class Request < AMQPMessage

      attr_accessor :is_async, :timeout, :respond_block, :response_class
      attr_reader :queue

      def initialize(exchange, options)
        super exchange, options
        @queue = Queue.new

        @response_class = options[:response_class] || ApiTools::Services::Response
      end

      def create_response(options = {})
        c_options = {
          :routing_key => reply_to,
          :request => self,
          :correlation_id => @message_id,
          :type => 'response',
        }
        c_options.merge!(options)
        response_class.new(exchange, c_options)
      end

      def is_async?
        @is_async
      end

      def timeout?
        @timeout
      end
    end
  end
end