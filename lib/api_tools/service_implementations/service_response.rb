########################################################################
# File::    service_response.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A high level description of a service's response to a
#           client's request. The middleware constructs instances and
#           fills in some of the data for every client request, then
#           passes it to ApiTools::ServiceImplementation methods so
#           the service can fill in the rest of the data.
# ----------------------------------------------------------------------
#           24-Sep-2014 (ADH): Created.
########################################################################

module ApiTools

  # The service middleware creates an ApiTools::ServiceResponse instance for
  # each request it handles, populating it with some data before and after the
  # service implementation runs as part of standard pre- and post-processing.
  # In the middle, the service implementation is given the instance and adds
  # its own data to it.
  #
  # The instance carries data about both error conditions and successful work.
  # In the successful case, #http_status_code and #body data is set by the
  # service and used in the response. In the error case (see #errors), the
  # HTTP status code is taken from the first error in the errors collection and
  # the response body will be the JSON representation of that collection - any
  # HTTP status code or response body data previously set by the service will
  # be ignored.
  #
  class ServiceResponse

    # Obtain a reference to the ApiTools::Errors instance for this response;
    # use ApiTools::Errors#add_error to add to the collection directly. For
    # convenience, this class also provides the #add_error proxy instance
    # method (syntactic sugar for most service implementations, but with a
    # return value that helps keep the service middleware code clean).
    #
    # It's possible to change the errors object if you want to swap it for any
    # reason, though this is generally discouraged - especially if the existing
    # errors collection isn't empty. The middleware does this as part of
    # request handling, but generally speaking nobody else should need to.
    #
    attr_accessor :errors

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
    attr_accessor :body

    # Create a new instance, ready to take on a response. The service
    # middleware responsible for doing this.
    #
    def initialize
      @errors           = ApiTools::Errors.new()
      @headers          = {}
      @http_status_code = 200
      @body             = {}
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
      dname = name.downcase
      value = value.to_s

      if ( overwrite == false && @headers.has_key?( dname ) )
        hash  = @headers[ dname ]
        name  = hash.keys[ 0 ]
        value = hash.values[ 0 ]
        raise "ApiTools::ServiceResponse\#add_header: Value '#{ value }' already defined for header '#{ name }'"
      else
        @headers[ dname ] = { name => value }
      end
    end

    # Check the stored value of a given HTTP header. Checks are case
    # insensitive. Returns the value stored by a prior #add_header call, or
    # +nil+ for no value (or an explicitly stored value of +nil+)
    #
    # +name+:: HTTP header name (e.g. "Content-Type", "CONTENT-TYPE").
    #
    def get_header( name )
      value_hash = @headers[ name.downcase ]
      return nil if value_hash.nil?
      return value_hash.values[ 0 ]
    end

    # Returns the list previously set headers in a name: value Hash.
    #
    def headers
      @headers.inject( {} ) do | result, kv_array |
        result.merge( kv_array[ 1 ] )
      end
    end

    # Add an error to the internal collection. Passes input parameters through
    # to ApiTools::Errors#add_error, so see that for details. For convenience,
    # returns the for-rack representation of the response so far, so that code
    # which wishes to add one error and abort request processing immediately
    # can just do:
    #
    #     return response_object.add_error( ... )
    #
    # ...as part of processing a Rack invocation of the +call+ method. This is
    # really only useful for the service middleware.
    #
    # +code+::    Error code (e.g. "platform.generic").
    # +options+:: Options Hash - see ApiTools::Errors#add_error.
    #
    # Example:
    #
    #     response.add_error(
    #       'generic.not_found',
    #       'message' => 'Optional custom message',
    #       'reference' => { :ident => 'mandatory reference data' }
    #     )
    #
    # In the above example, the mandatory reference data +uuid+ comes
    # from the description for the 'platform.not_found' message - see the
    # ApiTools::ErrorDescriptions#initialize _implementation_ and Platform API.
    #
    def add_error( code, options = nil )
      @errors.add_error( code, options )
      return for_rack()
    end

    # Add a precompiled error to the error collection. Pass error code,
    # error message and reference data directly.
    #
    # In most cases you should be calling #add_error instead, *NOT* here.
    #
    # **No validation is performed**. You should only really call here if
    # storing an error / errors from another, trusted source with assumed
    # validity (e.g. another service called remotely with errors in the JSON
    # response). It's possible to store invalid error data using this call,
    # which means counter-to-documentation results could be returned to API
    # clients. That is Very Bad.
    #
    # As with #add_error, returns a Rack representation of the response.
    #
    def add_precompiled_error( code, message, reference )
      @errors.add_precompiled_error( code, message, reference )
      return for_rack()
    end

    # Convert the internal response data into something that Rack expects.
    # The return value of this method can be passed back to Rack from Rack
    # middleware or applications.
    #
    def for_rack
      rack_response = Rack::Response.new

      # Work out the status code and basic response body

      if @errors.has_errors?
        http_status_code = @errors.http_status_code
        body_data        = @errors.render()
      else
        http_status_code = @http_status_code
        body_data        = @body
      end

      rack_response.status = http_status_code.to_i

      # We're not using JSON5, so the Platform API says that outmost arrays
      # are wrapped with a top-level object key "_data".

      if body_data.is_a?( Array )
        response_hash = { '_data' => body_data }
      else
        response_hash = body_data
      end

      rack_response.write( JSON.pretty_generate( response_hash ) )

      # Finally, sort out the headers

      headers().each do | header_name, header_value |
        rack_response[ header_name ] = header_value
      end

      # Return the complete response

      return rack_response.finish
    end
  end
end
