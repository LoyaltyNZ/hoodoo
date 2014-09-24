module ApiTools

  # A container for the Rack-based service middleware.
  #
  class ServiceMiddleware

    # Initialize the middleware instance.
    #
    # +app+ Rack app instance to which calls should be passed.
    #
    def initialize( app )
      @service = app

      unless @service.is_a?( ApiTools::ServiceApplication )
        raise "ApiTools::ServiceMiddleware instance created with non-ServiceApplication entity of class '#{ @service.class }' - is this the last middleware in the chain via 'use()' and is Rack 'run()'-ing the correct thing?"
      end

      @service.component_interfaces.each do | interface |

      end
    end

    # Run a Rack request, returning the [status, headers, body-array]
    # data as per the Rack protocol requirements.
    #
    # +env+ Rack environment.
    #
    def call( env )
      preprocessor = ApiTools::ServiceMiddleware::Preprocessor.new( env )
      preprocessor.preprocess()

      response = process( @service )

      postprocessor = ApiTools::ServiceMiddleware::Postprocessor.new( response )
      return postprocesor.postprocess()
    end

  private

    # Process the client's call. The heart of service routing and application
    # invocation. Relies entirely on data assembled during initialisation of
    # this middleware instance or during handling in #call.
    #
    def process
      #
      # endpoint_regexps = endpoints.map do | endpoint |
      #   /\/#{ endpoint }(.*)/
      # end
      #
      # endpoint_regexps.each_with_index do | regexp, index |
      #   match_data = uri_path.match( regexp )
      #   next if match_data.nil?
      #
      #   # The path matches, so we know which endpoint to use. Split what's left
      #   # of the path by "/", leaving path components in an array (which will
      #   # contain one empty string if there's no extra path data).
      #
      #   endpoint                  = endpoints[ index ]
      #
      #   ...missing part here, may as well immediately check that basic request
      #   details match up with the endpoint's specification. For example, it might
      #   not support the HTTP Method. Do the query parameter checks here too
      #   (i.e. common stuff but not e.g. the broken down bits of sort or search).'
      #
      #   remaining_path_components = match_data[ 1 ].split( '/' )
      #   last_item                 = remaining_path_components.last
      #
      #   # If the last item is empty, remove it from the array; else split it by
      #   # first "." into path and extension components, update the last array entry
      #   # with just the path and hold the extension separately.
      #
      #   if ( last_item == '' )
      #     remaining_path_components.pop()
      #   else
      #     path, extension = last_item.split( '.', 2 )
      #     if ( path == '' )
      #       remaining_path_components.pop()
      #     else
      #       remaining_path_components[ -1 ] = path
      #     end
      #   end
      #
      #   # Dispatch to service.
      #
      #   # (After loads of validation up front based on service declarations and
      #   # data types, e.g. does the Rack
      #
      #   ...assemble endpoint, remaining path components, extension, query
      #   parameters, parsed body data etc. into some formalised request details
      #   object then dispatch based on Rack method. Can have the unpacked unescaped
      #   data for search, filter, sort done here so it is structured not just a hash
      #   of parameters.
      #
      # end
    end
  end
end
