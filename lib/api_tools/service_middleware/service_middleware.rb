module ApiTools

  # A container for the Rack-based service middleware.
  #
  class ServiceMiddleware

    # Allowed action names (see #actions, #the_actions).
    #
    ALLOWED_ACTIONS = [ :list, :show, :create, :update, :delete ]

    # Initialize the middleware instance.
    #
    # +app+ Rack app instance to which calls should be passed.
    #
    def initialize( app )
      @service_container = app

      unless @service_container.is_a?( ApiTools::ServiceApplication )
        raise "ApiTools::ServiceMiddleware instance created with non-ServiceApplication entity of class '#{ @service_container.class }' - is this the last middleware in the chain via 'use()' and is Rack 'run()'-ing the correct thing?"
      end

      # Collect together the implementation instances and the matching regexps
      # for endpoints. An array of hashes.
      #
      # Key              Value
      # =======================================================================
      # regexp           Regexp for ".match" on the URI path component
      # interface        ApiTools::ServiceInterface instance to use on match
      # actions          Array of symbols naming allowed actions

      @services = @service_container.component_interfaces.map do | interface |

        if interface.nil? || interface.the_endpoint.nil? || interface.the_implementation.nil?
          raise "ApiTools::ServiceMiddleware encountered invalid interface class #{ interface.class } via service class #{ @app.class }"
        end

        # Regexp explanation:
        #
        # Match "/", the endpoint text, then either another "/", a "." or the
        # end of the string, followed by capturing everything else. Match data
        # index 1 will be whatever character (if any) followed after the
        # endpoint ("/" or ".") while index 2 contains everything else.

        {
          :actions   => interface.the_actions || ApiTools::ServiceInterface::ALLOWED_ACTIONS,
          :interface => interface.implementation.new,
          :regexp    => /\/#{ interface.endpoint }(\.|\/|$)(.*)/,
        }

      end
    end

    # Run a Rack request, returning the [status, headers, body-array]
    # data as per the Rack protocol requirements.
    #
    # +env+ Rack environment.
    #
    def call( env )
      preprocessor = ApiTools::ServiceMiddleware::Preprocessor.new( env )
      preprocessed = preprocessor.preprocess()

      # Global exception handler - catch problems in service implementations
      # and send back a 500 response as per API documentation (if possible).
      #
      begin
        response = process( preprocessed )

      rescue => exception
        begin
          raise exception # TODO return 500 - platform.fault

        rescue
          # An exception in the exception handler! Oh dear. Return a
          # HEAD-only response, more or less...
          #
          #   https://github.com/rack/rack/blob/master/lib/rack/head.rb#L12
          #
          return [
            500, {}, Rack::BodyProxy.new([]) do
              body.close if body.respond_to? :close
            end
          ]

        end
      end

      postprocessor = ApiTools::ServiceMiddleware::Postprocessor.new( response )
      return postprocesor.postprocess()
    end

  private

    # Process the client's call. The heart of service routing and application
    # invocation. Relies entirely on data assembled during initialisation of
    # this middleware instance or during handling in #call.
    #
    def process( preprocessed_request )

      # Select a service based on the escaped URI's path. If we find none,
      # then there's no matching endpoint; badly routed request; 404. If we
      # find many, raise an exception and rely on the exception handler to
      # send back a 500.

      uri_path = CGI.unescape( preprocessed_request.path() )

      selected_services = @services.select do | service_data |
        @path_data = process_uri_path( uri_path, service_data[ :regexp ] )
        not @path_data.nil?
      end

      if selected_services.size == 0
        # 404
        return
      elsif selected_services.size > 1
        raise "Multiple service endpoint matches - internal server configuration fault"
      else
        selected_service = selected_services[ 0 ]
      end

      uri_path_components, uri_path_extension = @path_data
      interface                               = selected_service[ :interface ]
      actions                                 = selected_service[ :actions   ]

      # Check for a supported action. Clumsy code because there is no 1:1 map
      # from HTTP method to action (e.g. GET can be :show or :list).

      supported_action = if preprocessed_request.post?
        :create if actions.include?( :create )
      elsif preprocessed_request.patch?
        :update if actions.include?( :update )
      elsif preprocessed_request.delete?
        :delete if actions.include?( :delete )
      elsif preprocessed_request.get?
        if path_components.size > 0
          :list if actions.include?( :list )
        else
          :show if actions.include?( :show )
        end
      end

      if supported_action.nil?
        raise "405" # TODO return 405 properly - platform.method_not_allowed
        return
      end

      # Looks good so far, so allocate a request object to pass on to the
      # interface and hold other higher level parsed data assembled below.

      service_request                     = ApiTools::ServiceRequest.new
      service_request.rack_request        = preprocessed_request
      service_request.uri_path_components = uri_path_components
      service_request.uri_path_extension  = uri_path_extension

      # What about the query string? Only do this if we know we want to keep
      # processing this request, because otherwise it's a waste of CPU cycles.
      # The 'decode' call produces an array of two-element arrays, the first
      # being the key and next being the value, already CGI unescaped once.

      query_data = URI.decode_www_form( preprocessed_request.query_string )
      query_hash = Hash[ query_data ]

      # service_request.list_offset = query_hash[ 'offset' ] || 0
      # service_request.list_limit  = query_hash[ 'limit' ] || interface... || default
      # service_request.list_sort_key = some_sort_key or default (string)
      # service_request.list_sort_direction = some direction or default (string)
      # service_request.list_search_data = hash or nil
      # service_request.list_filter_data = hash or nil


      #   ...missing part here, may as well immediately check that basic request
      #   details match up with the endpoint's specification. For example, it might
      #   not support the HTTP Method. Do the query parameter checks here too
      #   (i.e. common stuff but not e.g. the broken down bits of sort or search).'
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
      end

    private

      # Match a URI string against a service endpoint regexp and return broken
      # down path components and extension if there's a match, else nil.
      #
      # +uri_path+:: Path component of URI, percent-*unescaped*.
      # +regexp+::   A regexp that should return the separator between service
      #              endpoint and any other path data in match data index 1 and
      #              the rest of the URI path, if any, in match data 2.
      #
      # Returns an array with two elements. The first is the array of pure path
      # components, with no empty strings; it may be empty. The second is the
      # filename extension if present, else an empty string.
      #
      # Returns nil if there's no endpoint match at all.
      #
      # Example - assuming the regexp matched a service endpoint of "/members"
      # then URI paths yield example return values as follows:
      #
      #     /members
      #     => [ [], '' ]
      #
      #     /members.json
      #     => [ [], 'json' ]
      #
      #     /members/
      #     => [ [], '' ]
      #
      #     /members/1234.json
      #     => [ [ '1234' ], 'json' ]
      #
      #     /members/1234/hello.tar.gz
      #     => [ [ '1234', 'hello' ], 'tar.gz' ]
      #
      def process_uri_path( uri_path, regexp )
        match_data = uri_path.match( regexp )
        return nil if match_data.nil?

        # Split the path into array entries and examine the last one for a
        # filename extension, extracting it if found.

        remaining_path_components = []
        extension                 = ''

        if ( match_data[ 1 ] == '.' )
          extension = match_data[ 2 ]

        elsif ( match_data[ 1 ] == '/' )
          remaining_path_components = match_data[ 2 ].split( '/' ).reject { | str | str === '' }
          last_item                 = remaining_path_components.last

          unless ( last_item.nil? )
            path, extension = last_item.split( '.', 2 )

            if ( path == '' )
              remaining_path_components.pop()
            else
              remaining_path_components[ -1 ] = path
            end
          end
        end

        [ remaining_path_components, extension ]
      end

    end
  end
end
