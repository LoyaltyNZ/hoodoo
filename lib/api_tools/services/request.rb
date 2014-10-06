module ApiTools
  module Services
    class Request < AMQPMessage

      attr_accessor :is_async, :timeout, :response_class
      attr_reader :queue

      def initialize(options)
        super options
        @response_class = ApiTools::Services::Response

        @type = options[:type] || 'request'
        @queue = Queue.new
      end

      def create_response(options = {})
        c_options = {
          :routing_key => reply_to,
          :correlation_id => message_id,
          :type => 'response',
        }.merge(options)
        @response_class.new(c_options)
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