module ApiTools
  module Services
    class HTTPRequest < ApiTools::Services::Request

      attr_accessor :session_id, :host, :port, :path, :query, :verb, :scheme, :headers, :body

      def initialize(options = {})
        update options
        super options

        @type = options[:type] || 'http_request'
        @response_class = ApiTools::Services::HTTPResponse
      end

      def serialize
        @content = {
          :session_id => @session_id,
          :scheme => @scheme,
          :host => @host,
          :port => @port,
          :path => @path,
          :query => @query,
          :verb => @verb,
          :headers => @headers,
          :body => @body,
        }
        super
      end

      def deserialize
        super
        update @content
      end

      def update(options)
        @session_id = options[:session_id]
        @headers = options[:headers]
        @verb = options[:verb]
        @scheme = options[:scheme]
        @host = options[:host]
        @port = options[:port]
        @path = options[:path]
        @query = options[:query]
        @body = options[:body]
      end
    end
  end
end
