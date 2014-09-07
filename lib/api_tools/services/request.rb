module ApiTools
  module Services
    class Request

      attr_accessor :block, :queue, :message_id, :to

      def initialize(to, queue, message_id)
        @queue = queue
        @message_id = message_id
      end

      def call_block
        @block.call
      end

    end
  end
end