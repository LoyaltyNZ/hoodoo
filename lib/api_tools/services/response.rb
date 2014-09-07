module ApiTools
  module Services
    class Response

      attr_accessor :queue, :status, :payload

      def initialize(queue, status, payload)
        @queue = queue
        @status = status
        @payload = payload
      end

      def pending?
        @status == 'pending'
      end

      def success?
        @status == 'success'
      end

    end
  end
end