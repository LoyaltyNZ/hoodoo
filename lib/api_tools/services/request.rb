module ApiTools
  module Services
    class Request

      attr_accessor :block, :queue, :message_id, :to

      def initialize(to, queue, message_id)
        @queue = queue
        @message_id = message_id
        @state = :created
      end

      def call_block
        @block.call
      end

      def timed_out?
        @state == :timeout
      end

    end
  end
end