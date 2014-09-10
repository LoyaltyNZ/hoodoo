module ApiTools
  module Services
    class Response < AMQPMessage
      attr_accessor :request
    end
  end
end