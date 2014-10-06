module ApiTools
  module Services
    class Response < AMQPMessage
      def initialize(options = {})
        super options
        @type = options[:type] || 'response'
      end
    end
  end
end