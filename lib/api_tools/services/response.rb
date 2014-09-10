module ApiTools
  module Services
    class Response < ApiTools::Services::AMQPMessage
      attr_accessor :request
    end
  end
end