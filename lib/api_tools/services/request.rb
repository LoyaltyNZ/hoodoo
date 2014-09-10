module ApiTools
  module Services
    class Request < AMQPMessage

      attr_accessor :is_async, :timed_out, :respond_block
      attr_reader :queue

      def initialize(exchange, options)
        super exchange, options
        @queue = Queue.new
      end

      def create_response(options = {})
        c_options = {
          :routing_key => reply_to,
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

      def timed_out?
        @timed_out
      end
    end
  end
end