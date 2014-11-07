require 'json'

module ApiTools
  # A module intended as a sinatra extension, providing standard JSON parsing to the
  # `@payload` instance variable in the API call.
  module JsonPayload

    # Process the request body as JSON, and place a `Hash` of the parsed structure
    # in the `@payload` instance variable (:symbolize_names => false, all JSON keys
    # are strings). If the JSON parsing fails, `halt` the API call immediately returning
    # `400 Bad Request` and rendering any previously added errors plus a 'generic.bad_json'
    # error in the response body.
    #
    # +keys_as_symbols+:: If +true+ the JSON parsed `Hash` uses Symbols for keys instead
    #                     of strings. This is _NOT RECOMMENDED_ because of:
    #                     https://www.ruby-lang.org/en/news/2013/02/22/json-dos-cve-2013-0269/
    #
    def process_json_payload( keys_as_symbols = false )
      request.body.rewind
      body = request.body.read
      unless body.length > 2
        @payload = nil
        return
      end

      begin
        @payload = JSON.parse body, :symbolize_names => keys_as_symbols
      rescue JSON::ParserError
        @payload = nil
        fail_with_error 400, 'generic.bad_json',  'The JSON payload cannot be parsed'
      end
    end
  end
end