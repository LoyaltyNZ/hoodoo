require 'msgpack'

module ApiTools
  module Services
    class AMQPMessage
      attr_accessor :message_id, :routing_key, :correlation_id, :type, :reply_to, :content_type
      attr_accessor :payload, :content, :received_by

      def initialize(options = {})
        @message_id = options[:message_id] || ApiTools::UUID.generate
        @routing_key = options[:routing_key]
        @correlation_id = options[:correlation_id]
        @type = options[:type] || 'other'
        @reply_to = options[:reply_to]
        @content_type = options[:content_type] || 'application/octet-stream'
        @received_by = options[:received_by]
        @payload = options[:payload]

        deserialize unless @payload.nil?
      end

      def serialize
        @payload = @content.to_msgpack
      end

      def deserialize
        @content = MessagePack.unpack(@payload, :symbolize_keys => true)
      end

      def self.create_from_raw_message(delivery_info, metadata, payload)
        new(
          :message_id => metadata.message_id,
          :type => metadata.type,
          :correlation_id => metadata.correlation_id,
          :reply_to => metadata.reply_to,
          :content_type => metadata.content_type,
          :received_by => delivery_info.routing_key,
          :payload => payload,
        )
      end
    end
  end
end