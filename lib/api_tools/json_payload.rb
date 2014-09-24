require 'json'

module ApiTools
  # A module intended as a sinatra extension, providing standard JSON parsing to the
  # `@payload` instance variable in the API call.
  module JsonPayload

    # Process the request body as JSON, and place a `Hash` of the parsed structure
    # in the `@payload` instance variable (:symbolize_names => true, all JSON keys
    # are symbols). If the JSON parsing fails, `halt` the API call immediately returning
    # `400 Bad Request` and rendering any previously added errors plus a 'generic.bad_json'
    # error in the response body.
    def process_json_payload
      request.body.rewind
      body = request.body.read
      unless body.length > 2
        @payload = nil
        return
      end

      begin
        @payload = JSON.parse body, :symbolize_names => true
      rescue JSON::ParserError
        @payload = nil
        fail_with_error 400, 'generic.bad_json',  'The JSON payload cannot be parsed'
      end
    end
  end
end