require "json"

module ApiTools
  module Services
    class HTTPJSONResponse < ApiTools::Services::Response

      attr_accessor :session_id, :headers, :status_code, :status_message, :body

      def initialize(exchange, options = {})
        super exchange, options

        @status_code = options[:status_code] || 200
        @status_message = options[:status_message] || 'OK'
        @headers = options[:headers] || []
        @body = options[:body]

        parse_payload(options[:payload]) if options.has_key?(:payload)
        parse_data(options[:data]) if options.has_key?(:data)
      end

      def payload
        JSON.fast_generate({
          :session_id => session_id,
          :http => {
            :headers => headers,
            :status => {
              :code => status_code,
              :message => status_message,
            },
          },
          :body => @body,
        })
      end

      def payload=(value)
        parse_payload(value)
      end

      def parse_payload(value)
        value = JSON.parse(value, :symbolize_names =>true)
        @session_id = value[:session_id]
        if value[:http]
          @status_code = value[:http][:status][:code]
          @status_message = value[:http][:status][:message]
          @headers = value[:http][:headers]
        end
        @body = value[:body]
      end

      def data
        (@body.is_a?(String) && @body.length>1) ? JSON.parse(@body) : nil
      end

      def data=(value)
        parse_data(value)
      end

      def parse_data(value)
        @body = JSON.fast_generate(value) if value.is_a?(Hash)
      end

    end
  end
end
