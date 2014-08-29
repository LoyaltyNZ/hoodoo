require 'json'

module ApiTools
  module JsonErrors
    include PlatformErrors
    def fail_with_error(status, code, message, reference = nil)
      add_error code,message,reference
      fail_with_errors status
    end

    def fail_with_errors(status = 422, errors = nil)
      if errors.is_a?(Array)
        @errors += errors
      end
      halt status, JSON.fast_generate({
        :errors => @errors
      })
    end

    def fail_not_found
      fail_with_errors 404
    end

    def fail_unauthorized
      fail_with_error 401, 'platform.unauthorized','Authorization is required to perform this operation on the resource.'
    end

    def fail_forbidden
      fail_with_error 403, 'platform.forbidden','The user is not allowed to perform this operation on the resource.'
    end
  end
end