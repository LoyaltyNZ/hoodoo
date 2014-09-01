require 'json'

module ApiTools
  # A module intended as a sinatra extension, providing standard error functionality for 
  # Platform APIs. Methods are provided to add multiple error conditions, halt the API, 
  # and render the standard platform JSON error structure.
  module JsonErrors
    include PlatformErrors

    # `halt` the API call immediately, returning the supplied HTTP `status` code,
    # and render any previously added errors plus an error with the supplied 
    # `code`, `message`, and optionally `reference`, in the response body.
    # Params:
    # +status+:: +Integer+ The HTTP status code to halt with
    # +code+:: +String+ The error code to return
    # +message+:: +String+ The error message to return
    # +reference+:: +String+ The error reference (optional)
    def fail_with_error(status, code, message, reference = nil)
      add_error code,message,reference
      fail_with_errors status
    end

    # halt` the API call immediately, returning the supplied HTTP `status` code, 
    # with any previously added errors plus all supplied `errors` in the response 
    # body. Please note `errors` should be an array of hashes conforming to the 
    # standard error interface.
    # Params:
    # +status+:: +Integer+ The HTTP status code to halt with (optional, defaults to 422)
    # +errors+:: +Array+ Any new errors to add. (optional)
    def fail_with_errors(status = 422, errors = nil)
      if errors.is_a?(Array)
        @errors += errors
      end
      halt status, JSON.fast_generate({
        :errors => @errors
      })
    end

    # `halt` the API call immediately, returning `404 Not Found` and rendering any 
    # previously added errors in the response body.
    def fail_not_found
      fail_with_errors 404
    end

    # `halt` the API call immediately, returning `401 Unauthorized` and rendering any 
    # previously added errors plus a `platform.unauthorized` error in the response body.
    def fail_unauthorized
      fail_with_error 401, 'platform.unauthorized','Authorization is required to perform this operation on the resource.'
    end

    # `halt` the API call immediately, returning `403 Forbidden` and rendering any 
    # previously added errors plus a 'platform.forbidden' error in the response body. 
    def fail_forbidden
      fail_with_error 403, 'platform.forbidden','The user is not allowed to perform this operation on the resource.'
    end
  end
end