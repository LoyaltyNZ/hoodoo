module ApiTools
  module Services
    class AMQPMessage
      attr_accessor :message_id, :routing_key, :correlation_id, :type, :reply_to, :payload, :content_type, :received_by
      attr_reader :exchange

      def initialize(c_exchange, options = {})
        @exchange = c_exchange
        @message_id = options[:message_id] || ApiTools::UUID.generate
        @routing_key = options[:routing_key]
        @correlation_id = options[:correlation_id]
        @type = options[:type] || 'other'
        @reply_to = options[:reply_to]
        @payload = options[:payload]
        @content_type = options[:content_type]
        @received_by = options[:received_by]
      end

      def send_message
        @message_id ||= ApiTools::UUID.generate
        options = {
          :message_id => message_id,
          :routing_key => routing_key,
          :type => type,
          :correlation_id => correlation_id,
          :content_type => content_type,
          :reply_to => reply_to,
        }
        exchange.publish(payload, options)
      end
    end
  end
end