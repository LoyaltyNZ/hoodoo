########################################################################
# File::    service_middleware.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Rack middleware, declared in a +config.ru+ file in the usual
#           way - "use( ApiTools::ServiceMiddleware )".
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module ApiTools

  # Rack middleware, declared in (e.g.) a +config.ru+ file in the
  # usual way:
  #
  #     use( ApiTools::ServiceMiddleware )
  #
  # This is the core of the common service implementation on the
  # Rack client-request-handling side. It is run in the context
  # of an ApiTools::ServiceApplication subclass that's been
  # given to Rack as the Rack endpoint application; it looks at
  # the component interfaces supported by the service and routes
  # requests to the correct one (or raises a 404).
  #
  # Lots of preprocessing and postprocessing gets done to set up
  # things like locale information, enforce content types and
  # so-forth. Request data is assembled in a parsed, structured
  # format for passing to service implementations and a response
  # object built so that services have a consistent way to
  # return results, which can be post-processed further by the
  # middleware before returning the data to Rack.
  #
  class ServiceMiddleware

    # All allowed action names in implementations, used for internal checks.
    # This is also the default supported set of actions. Symbols.
    #
    ALLOWED_ACTIONS = [
      :list,
      :show,
      :create,
      :update,
      :delete,
    ]

    # Allowed common fields in query strings (list actions only). Strings.
    #
    # Only ever *add* to this list. As the API evolves, legacy clients will
    # be calling with previously documented query strings and removing any
    # entries from the list below could cause their requests to be rejected
    # with a 'platform.malformed' error.
    #
    ALLOWED_QUERIES = [
      'offset',
      'limit',
      'sort',
      'direction',
      'search',
      'filter',
      '_embed',
      '_reference',
    ]

    # Allowed media types in Content-Type headers.
    #
    SUPPORTED_MEDIA_TYPES = [ 'application/json' ]

    # Allowed (required) charsets in Content-Type headers.
    #
    SUPPORTED_ENCODINGS = [ 'utf-8' ]

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
      # regexp           Regexp for +String#match+ on the URI path component
      # interface        ApiTools::ServiceInterface subclass associated with
      #                  the endpoint regular expression in +regexp+
      # actions          Array of symbols naming allowed actions
      # implementation   ApiTools::ServiceImplementation subclass *instance* to
      #                  use on match

      @services = @service_container.component_interfaces.map do | interface |

        if interface.nil? || interface.endpoint.nil? || interface.implementation.nil?
          raise "ApiTools::ServiceMiddleware encountered invalid interface class #{ interface.class } via service class #{ @app.class }"
        end

        # Regexp explanation:
        #
        # Match "/", the endpoint text, then either another "/", a "." or the
        # end of the string, followed by capturing everything else. Match data
        # index 1 will be whatever character (if any) followed after the
        # endpoint ("/" or ".") while index 2 contains everything else.

        {
          :regexp         => /\/#{ interface.endpoint }(\.|\/|$)(.*)/,
          :interface      => interface,
          :actions        => interface.actions || ALLOWED_ACTIONS,
          :implementation => interface.implementation.new
        }

      end
    end

    # Run a Rack request, returning the [status, headers, body-array] data as
    # per the Rack protocol requirements.
    #
    # +env+ Rack environment.
    #
    def call( env )

      # Global exception handler - catch problems in service implementations
      # and send back a 500 response as per API documentation (if possible).
      #
      begin

        @request  = Rack::Request.new( env )
        @response = ApiTools::ServiceResponse.new

        preprocess()
        return @response.for_rack() if @response.halt_processing?

        process()
        return @response.for_rack() if @response.halt_processing?

        postprocess()
        return @response.for_rack()

      rescue => exception
        begin

          return @response.add_error(
            'platform.fault',
            :message => exception.message
          )

        rescue

          # An exception in the exception handler! Oh dear. Return a
          # HEAD-only response.
          #
          return [
            500, {}, Rack::BodyProxy.new([]) {}
          ]

        end
      end
    end

  private

    # Run request preprocessing - common actions that occur prior to any service
    # instance selection or service-specific processing.
    #
    # On exit, +@request+ or +@response+ may have been updated. Be sure to check
    # +@request.halt_processing?+ to see if processing should abort and return
    # immediately.
    #
    def preprocess
      check_content_type_header()

      @locale         = deal_with_language_header()
      @interaction_id = find_or_generate_interaction_id()
      @payload_hash   = payload_to_hash()
    end

    # Process the client's call. The heart of service routing and application
    # invocation. Relies entirely on data assembled during initialisation of
    # this middleware instance or during handling in #call.
    #
    def process

      # Select a service based on the escaped URI's path. If we find none,
      # then there's no matching endpoint; badly routed request; 404. If we
      # find many, raise an exception and rely on the exception handler to
      # send back a 500.

      uri_path = CGI.unescape( @request.path() )

      selected_services = @services.select do | service_data |
        @path_data = process_uri_path( uri_path, service_data[ :regexp ] )
        not @path_data.nil?
      end

      if selected_services.size == 0
        return @response.add_error(
          'platform.not_found',
          :reference => { :entity_name => '' }
        )
      elsif selected_services.size > 1
        raise "Multiple service endpoint matches - internal server configuration fault"
      else
        selected_service = selected_services[ 0 ]
      end

      uri_path_components, uri_path_extension = @path_data
      interface                               = selected_service[ :interface      ]
      actions                                 = selected_service[ :actions        ]
      implementation                          = selected_service[ :implementation ]

      # Check for a supported action. Clumsy code because there is no 1:1 map
      # from HTTP method to action (e.g. GET can be :show or :list).

      supported_action = if @request.post?
        :create if actions.include?( :create )
      elsif @request.patch?
        :update if actions.include?( :update )
      elsif @request.delete?
        :delete if actions.include?( :delete )
      elsif @request.get?
        if uri_path_components.size > 0
          :list if actions.include?( :list )
        else
          :show if actions.include?( :show )
        end
      end

      if supported_action.nil?
        return @response.add_error(
          'platform.method_not_allowed',
          :message => "Service endpoint '/#{ interface.endpoint }' does not support HTTP method '#{ env[ 'REQUEST_METHOD' ] }'"
        )
      end

      # Looks good so far, so allocate a request object to pass on to the
      # interface and hold other higher level parsed data assembled below.

      service_request                     = ApiTools::ServiceRequest.new
      service_request.rack_request        = @request
      service_request.uri_path_components = uri_path_components
      service_request.uri_path_extension  = uri_path_extension

      # Update the response object's errors collection in light of additional
      # service interface error descriptions, if any.

      unless interface.errors_for.nil?
        @response.errors = ApiTools::Errors.new( interface.errors_for )
      end

      # There should only be a query string for GET methods that ask for lists
      # of resources.

      if supported_action != :list && ( ! @request.query_string.nil? || @request.query_string != '' )
        return @response.add_error( 'platform.malformed' )
      else
        error = process_query_string( @request.query_string, service_request )
        return error unless error.nil?
      end

      # Finally - dispatch to service.

      implementation.send( supported_action,
                           service_request,
                           @response )
    end

    # Run request preprocessing - common actions that occur after service
    # instance selection and service-specific processing.
    #
    # On exit, +@response+ may have been updated.
    #
    def postprocess
      # TODO: Anything...?
    end

    # Check the client's +Content-Type+ header and if it doesn't ask for the
    # supported content types or text encodings, set a response error to force
    # a halt of any further processing (subject to the caller checking for
    # response errors afterwards).
    #
    # On success, +@content_type+ contains the requested media type (e.g.
    # +application/json+) and +@content_encoding+ contains the requested
    # encoding (e.g. +utf-8+).
    #
    def check_content_type_header
      unless SUPPORTED_MEDIA_TYPES.include?( @request.media_type ) &&
             SUPPORTED_ENCODINGS.include?( @request.content_charset )

        @errors.add_error(
          'platform.malformed',
          :message => "Content-Type '#{ @request.content_type }' does not match supported types '#{ SUPPORTED_MEDIA_TYPES }' and/or encodings '#{ SUPPORTED_ENCODINGS }'"
        )

      end
    end

    # Extract the +Content-Language+ header value from the client and store it
    # in +@request_locale+.
    #
    # TODO: No processing or validation is done on the client's value, to
    #       ensure it conforms to platform internationalisation rules.
    #
    def deal_with_language_header
      @request_locale = @request.env[ 'HTTP_CONTENT_LANGUAGE' ]
    end

    # Find the value of an X-Interaction-ID header (if one is already present)
    # or generate a new Interaction ID and store the result for the response,
    # as a new X-Interaction-ID header.
    #
    def find_or_generate_interaction_id
      iid = @request.env[ 'HTTP_X_INTERACTION_ID' ]
      iid = ApiTools::UUID.generate() if iid.nil? || iid == ''

      @response.add_header( 'X-Interaction-ID', iid )
    end

    # Safely parse the client payload for +POST+ and +PATCH+ into instance
    # variable +@payload_hash+.
    #
    def payload_to_hash
      return unless @request.post? or @request.patch?

      begin
        case @content_type
          when 'application/json'

            # We're aiming for Ruby 2.1 or later, but might end up on 1.9.
            #
            # https://www.ruby-lang.org/en/news/2013/02/22/json-dos-cve-2013-0269/
            #
            @payload_hash = JSON.parse( json, :create_additions => false )

          else
            raise "Internal error - content type #{ @content_type } is not supported here; \#check_content_type_header() should have caught that"
        end

      rescue => e
        @errors.add_error( 'generic.malformed' )
      end
    end

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

    # Process query string data for list actions. Only call if there's a list
    # action being requested.
    #
    # +query_string+::   The 'raw' query string from Rack.
    # +service_request:: An ApiTools::ServiceRequest instance. This will be
    #                    updated if successful with list parameter data.
    #
    # Returns +nil+ on success, else an error expressed as a Rack response
    # array - this can be passed directly back to Rack.
    #
    def process_query_string( query_string, service_request )

      # The 'decode' call produces an array of two-element arrays, the first
      # being the key and next being the value, already CGI unescaped once.

      query_data = URI.decode_www_form( query_string )
      query_hash = Hash[ query_data ]

      unrecognised_query_keys = query_hash - ALLOWED_QUERIES
      malformed = unrecognised_query_keys unless unrecognised_query_keys.empty?

      unless malformed
        limit     = query_hash[ 'limit' ] || interface.to_list.limit
        malformed = :limit unless limit.to_i.to_s == limit
      end

      unless malformed
        offset    = query_hash[ 'offset' ] || 0
        malformed = :offset unless offset.to_i.to_s == offset
      end

      unless malformed
        sort_key  = query_hash[ 'sort' ] || interface.to_list.default_sort_key
        malformed = :sort unless interface.to_list.sort.keys.include?( sort_key )
      end

      unless malformed
        direction = query_hash[ 'direction' ] || interface.to_list.default_sort_direction
        malformed = :direction unless interface.to_list.sort[ sort_key ].include?( direction )
      end

      unless malformed
        search = query_hash[ 'search' ]
        unless search.nil?
          search = Hash[ URI.decode_www_form( search ) ]
          unrecognised_search_keys = search.keys - interface.to_list.search
          malformed = "search:#{ unrecognised_search_keys }" unless unrecognised_search_keys.empty?
        end
      end

      unless malformed
        filter = query_hash[ 'filter' ]
        unless filter.nil?
          filter = Hash[ URI.decode_www_form( filter ) ]
          unrecognised_filter_keys = filter.keys - interface.to_list.filter
          malformed = "filter:#{ unrecognised_filter_keys }" unless unrecognised_filter_keys.empty?
        end
      end

      unless malformed
        embeds = query_hash[ '_embed' ]
        unless embeds.nil?
          embeds = embeds.split( ',' )
          unrecognised_embeds = embeds - interface.to_list.embeds
          malformed = "_embed:#{ unrecognised_embeds }" unless unrecognised_embeds.empty?
        end
      end

      unless malformed
        references = query_hash[ '_reference' ]
        unless references.nil?
          references = references.split( ',' )
          unrecognised_references = references - interface.to_list.references
          malformed = "_reference:#{ unrecognised_references }" unless unrecognised_references.empty?
        end
      end

      if malformed
        return @response.add_error(
          'platform.malformed',
          :message => "One or more malformed or invalid query string parameters: '#{ malformed }'"
        )
      end

      service_request.list_offset         = offset
      service_request.list_limit          = limit
      service_request.list_sort_key       = sort_key
      service_request.list_sort_direction = direction
      service_request.list_search_data    = search
      service_request.list_filter_data    = filter
      service_request.list_embeds         = embeds
      service_request.list_references     = references

      return nil
    end

  end
end
