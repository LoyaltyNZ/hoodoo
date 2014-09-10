module ApiTools
  module Services
    class AMQPMessage
      attr_accessor :message_id, :routing_key, :correlation_id, :type, :reply_to, :payload, :content_type
      attr_reader  :exchange

      def initialize(exchange, options = {})
        @exchange = exchange
        options.each { |k,v| send("#{k}=".to_sym,v) }
      end

      def send_message
        @message_id ||= ApiTools::UUID.generate
        exchange.publish(payload, {
          :message_id => message_id,
          :routing_key => routing_key,
          :type => type,
          :correlation_id => correlation_id,
          :content_type => content_type,
          :reply_to => reply_to,
        })
      end
    end
  end
end