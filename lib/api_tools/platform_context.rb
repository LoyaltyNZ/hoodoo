require 'json'

module ApiTools
  # A module intended as a sinatra extension, providing standard platform context to 
  # the API.
  module PlatformContext

    # Get the platform context from the `X-Subscriber-ID` and `X-Programme-ID` HTTP
    # headers into the `@platform_context` instance variable. If either or both headers 
    # are not supplied or empty, `halt` the API request with `400 Bad Request`, rendering 
    # the `platform.subscriber_id_required` and/or `platform.programme_id_required` errors 
    # in the standard format as required.
    def check_platform_context 
      
      @platform_context = {
        :subscriber_id => request.env['HTTP_X_SUBSCRIBER_ID'],
        :programme_id => request.env['HTTP_X_PROGRAMME_ID']
      }

      add_error('platform.subscriber_id_required','Please supply a `X-Subscriber-Id` HTTP header',nil) if @platform_context[:subscriber_id].nil? or @platform_context[:subscriber_id].empty?
      add_error('platform.programme_id_required','Please supply a `X-Programme-Id` HTTP header',nil) if @platform_context[:programme_id].nil? or @platform_context[:programme_id].empty?
    
      fail_with_errors 400 if has_errors?
    end

    # Return a string of the format `<subscriber_id>:<programme_id>:`
    def platform_context_prefix
      @platform_context[:subscriber_id]+":"+@platform_context[:programme_id]+":"
    end
  end
end