module ApiTools
  module Services
    class HTTPResponse < ApiTools::Services::Response

      attr_accessor :session_id, :headers, :status_code, :body

      def initialize(options = {})
        update options
        super options
      end

      def serialize
        @content = {
          :session_id => @session_id,
          :status_code => @status_code,
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
        @status_code = options[:status_code]
        @headers = options[:headers]
        @body = options[:body]
      end

    end
  end
end
