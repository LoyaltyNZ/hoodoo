require 'json'

module ApiTools
  module PlatformContext

    def check_platform_context 
      
      @platform_context = {
        :subscriber_id => request.env['HTTP_X_SUBSCRIBER_ID'],
        :programme_id => request.env['HTTP_X_PROGRAMME_ID']
      }

      add_error('platform.subscriber_id_required','Please supply a `X-Subscriber-Id` HTTP header',nil) if @platform_context[:subscriber_id].nil? or @platform_context[:subscriber_id].empty?
      add_error('platform.programme_id_required','Please supply a `X-Programme-Id` HTTP header',nil) if @platform_context[:programme_id].nil? or @platform_context[:programme_id].empty?
    
      fail_with_errors 400 if has_errors?
    end

    def platform_context_prefix
      @platform_context[:subscriber_id]+":"+@platform_context[:programme_id]+":"
    end
  end
end