require "json"

module ApiTools
  module Services
    class HTTPJSONRequest < ApiTools::Services::Request

      attr_accessor :session_id, :host, :port, :path, :query, :verb, :headers, :body

      def initialize(exchange, options = {})
        super exchange, options

        @session_id = options[:session_id]
        @host = options[:host]
        @port = options[:port]
        @path = options[:path]
        @query = options[:query]
        @verb = options[:verb]
        @headers = options[:headers]
        @body= options[:body]

        parse_payload(options[:payload]) if options.has_key?(:payload)
        parse_data(options[:data]) if options.has_key?(:data)

        @response_class = options[:response_class] || ApiTools::Services::HTTPJSONResponse
      end

      def payload
        JSON.fast_generate({
          :session_id => session_id,
          :http => {
            :host => host,
            :port => port,
            :path => path,
            :query => query,
            :verb => verb,
            :headers => headers,
          },
          :body => @body,
        })
      end

      def payload=(value)
        parse_payload(value)
      end

      def parse_payload(value)
        if value.is_a?(String) and value.length>1
          value = JSON.parse(value, :symbolize_names => true)
          @session_id = value[:session_id]
          @host = value[:http][:host]
          @port = value[:http][:port]
          @path = value[:http][:path]
          @verb = value[:http][:verb].to_sym
          @headers = value[:http][:headers]
          @body = value[:body]
        end
      end

      def data=(value)
        parse_data(value)
      end

      def data
        (@body.is_a?(String) && @body.length>1) ? JSON.parse(@body, :symbolize_names => true) : nil
      end

      def parse_data(value)
        @body = JSON.fast_generate(value) if value.is_a?(Hash)
      end
    end
  end
end
