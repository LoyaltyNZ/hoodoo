require "msgpack"

module ApiTools
  module Services
    class HTTPRequest < ApiTools::Services::Request

      attr_accessor :session_id, :host, :port, :path, :query, :verb, :headers, :body

      def initialize(exchange, options = {})
        super exchange, options

        update(options)

        @response_class = options[:response_class] || ApiTools::Services::HTTPResponse
      end

      def serialize
        @content = {
          :session_id => @session_id,
          :host => @host,
          :port => @port,
          :path => @path,
          :query => @query,
          :verb => @verb,
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
        @host = hash[:host]
        @port = hash[:port]
        @path = hash[:path]
        @query = hash[:query]
        @verb = hash[:verb]
        @headers = hash[:headers]
        @body = hash[:body]
      end
    end
  end
end
