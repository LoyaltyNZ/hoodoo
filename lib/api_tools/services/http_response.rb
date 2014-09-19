require "json"

module ApiTools
  module Services
    class HTTPResponse < ApiTools::Services::Response

      attr_accessor :session_id, :headers, :status_code, :status_message, :body

      def initialize(exchange, options = {})
        super exchange, options

        update(options)
      end

      def serialize
        @content = {
          :session_id => @session_id,
          :status_code => @status_code,
          :headers => @headers,
          :body => @body,
        }
        @payload = @content.to_msgpack
      end

      def deserialize
        @content = MessagePack.unpack(@payload, :symbolize_keys => true)
        update(@content)
      end

      private

      def update(hash)
        @session_id = hash[:session_id]
        @status_code = hash[:status_code]
        @headers = hash[:headers]
        @body = hash[:body]
      end

    end
  end
end
