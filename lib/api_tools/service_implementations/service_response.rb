module ApiTools

  # The service middleware creates an ApiTools::ServiceResponse instance for
  # each request it handles, populating it with some data before and after the
  # service implementation runs as part of standard pre- and post-processing.
  # In the middle, the service implementation is given the instance and adds
  # its own data to it.
  #
  # The instance carries data about both error conditions and successful work.
  # In the successful case, #http_status_code and #response_body data is set by
  # the service and used in the response. In the error case (see #errors), the
  # HTTP status code is taken from the first error in the errors collection and
  # the response body will be the JSON representation of that collection - any
  # HTTP status code or response body data previously set by the service will
  # be ignored.
  #
  class ServiceResponse

    # Obtain a reference to the ApiTools::Errors instance for this response;
    # use ApiTools::Errors#add_error to add to the collection directly.
    #
    attr_reader :errors

    # HTTP status code that will be involved in the response. Default is 200.
    # Integer, or something that can be converted to one with +to_i+. If errors
    # are added to the response then the status code is derived from the first
    # error in the collection, overriding any value set here. See #errors.
    #
    attr_accessor :http_status_code

    # A service implementation sets (and reads back, should it wish) the
    # API call response body data using this accessor. This is converted to a
    # client-facing representation automatically (e.g. to JSON).
    #
    # The response body *MUST* be either a *Ruby Array* or a *Ruby Hash*.
    #
    attr_accessor :response_body

    # Create a new instance, ready to take on a response. The service
    # middleware responsible for doing this.
    #
    def initialize
      @errors           = ApiTools::Errors.new()
      @headers          = {}
      @http_status_code = 200
      @response_body    = {}
    end

    # Returns +true+ if processing should halt, e.g. because errors have been
    # added to the errors collection. Check here whenever you would consider an
    # early exit due to errors arising in processing (otherwise they will just
    # continue to accumulate).
    #
    def halt_processing?
      @errors.has_errors?
    end

    # Add an HTTP header to the internal collection that will be used for the
    # response. Trying to set data for the same HTTP header name more than once
    # will result in an exception being raised unless the +overwrite+ parameter
    # is used (this is strongly discouraged in the general case).
    #
    # +name+::      Correct case and punctuation HTTP header name (e.g.
    #               "Content-Type").
    #
    # +value+::     Value for the header, as a string or something that behaves
    #               sensibly when +to_s+ is invoked upon it.
    #
    # +overwrite+:: Optional. Pass +true+ to allow the same HTTP header name to
    #               be set more than once - the new value overwrites the old.
    #               By default this is prohibited and an exception will be
    #               raised to avoid accidental value overwrites.
    #
    def add_header( name, value, overwrite = false )
      name = name.to_s
      value = value.to_s

      if ( overwrite == false && @headers.has_key?( name.downcase ) )
        raise "ApiTools::ServiceResponse\#add_header: Value '#{ value }' already defined for header '#{ name }'"
      else
        @headers[ name.downcase ] = { name => value }
      end
    end

    # Convert the internal response data into something that Rack expects.
    # The return value of this method can be passed back to Rack from Rack
    # middleware or applications.
    #
    def for_rack
      http_headers = {}

      @headers.each do | downcased_guard_name, original_name_value_hash |
        http_headers.merge!( original_name_value_hash )
      end

      if @errors.has_errors?

        [
          http_headers,
        ]

      else

        # We're not using JSON5, so the Platform API says that outmost arrays
        # are wrapped with a top-level object key "_data".

        if @response_body.is_a?( Array )
          response_hash = { '_data' => @response_body }
        else
          response_hash = @response_body
        end

        [
          @http_status_code.to_i,
          http_headers,
          JSON.generate( response_hash )
        ]

      end
    end
  end
end
