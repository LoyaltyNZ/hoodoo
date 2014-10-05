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

    # Somewhat arbitrary maximum incoming payload size to prevent ham-fisted
    # DOS attempts to consume RAM.
    #
    MAXIMUM_PAYLOAD_SIZE = 1048576 # 1MB Should Be Enough For Anyone

    # Utility - returns the execution environment as a Rails-like environment
    # object which answers queries like +production?+ or +staging?+ with +true+
    # or +false+ according to the +RACK_ENV+ environment variable setting.
    #
    # Example:
    #
    #     if ApiTools::ServiceMiddleware.environment.production?
    #       # ...do something only if RACK_ENV="production"
    #     end
    #
    def self.environment
      @_env ||= ApiTools::StringInquirer.new( ENV[ 'RACK_ENV' ] || 'development' )
    end

    # Initialize the middleware instance.
    #
    # +app+ Rack app instance to which calls should be passed.
    #
    def initialize( app )
      @service_container = app

      unless @service_container.is_a?( ApiTools::ServiceApplication )
        raise "ApiTools::ServiceMiddleware instance created with non-ServiceApplication entity of class '#{ app.class }' - is this the last middleware in the chain via 'use()' and is Rack 'run()'-ing the correct thing?"
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
          raise "ApiTools::ServiceMiddleware encountered invalid interface class #{ interface } via service class #{ app.class }"
        end

        # Regexp explanation:
        #
        # Match "/", the version text, "/", the endpoint text, then either
        # another "/", a "." or the end of the string, followed by capturing
        # everything else. Match data index 1 will be whatever character (if
        # any) followed after the endpoint ("/" or ".") while index 2 contains
        # everything else.

        {
          :regexp         => /\/v#{ interface.version }\/#{ interface.endpoint }(\.|\/|$)(.*)/,
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
        @session  = ApiTools::ServiceSession.new

        # TODO: Session validation/recovery, probably in preprocess()

        preprocess()
        return @response.for_rack() if @response.halt_processing?

        process()
        return @response.for_rack() if @response.halt_processing?

        postprocess()
        return @response.for_rack()

      rescue => exception
        begin

          reference = {
            :exception => exception.message
          }

          unless self.class.environment.production? || self.class.environment.uat?
            reference[ :backtrace ] = exception.backtrace.join( " | " )
          end

          return @response.add_error(
            'platform.fault',
            :message => exception.message,
            :reference => reference
          )

        rescue

          # An exception in the exception handler! Oh dear.
          #
          return [
            500, {}, Rack::BodyProxy.new(['Middleware exception in exception handler']) {}
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

      set_common_response_headers()
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
        path_data = process_uri_path( uri_path, service_data[ :regexp ] )

        if path_data.nil?
          false
        else
          @path_data = path_data
          true
        end
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

      action = if @request.post?
        :create
      elsif @request.patch?
        :update
      elsif @request.delete?
        :delete
      elsif @request.get?
        if uri_path_components.size == 0
          :list
        else
          :show
        end
      end

      unless actions.include?( action )
        return @response.add_error(
          'platform.method_not_allowed',
          :message => "Service endpoint '/v#{ interface.version }/#{ interface.endpoint }' does not support HTTP method '#{ @request.env[ 'REQUEST_METHOD' ] }' yielding action '#{ action }'"
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

      if action != :list && ! @request.params.empty?
        return @response.add_error( 'platform.malformed',
                                    :message => 'No query data is allowed for this action',
                                    :reference => { :action => action } )
      else
        error = process_query_string( @request.query_string, interface, service_request )
        return error unless error.nil?
      end

      # There should be no spurious path data for "list" or "create" actions -
      # only "show", "update" and "delete" take extra data via the URL's path.
      # Conversely, other actions require it.

      if action == :list || action == :create
        return @response.add_error( 'platform.malformed',
                                    :message => 'Unexpected path components for this action',
                                    :reference => { :action => action } ) unless uri_path_components.empty?
      else
        return @response.add_error( 'platform.malformed',
                                    :message => 'Expected path components identifying target resource instance for this action',
                                    :reference => { :action => action } ) if uri_path_components.empty?
      end

      # There should be no spurious body data for anything other than "create"
      # or "update" actions. This is one of the last things we do as it is
      # potentially very heavyweight.
      #
      # To try and be helpful to clients which may use HTTP libraries that
      # always write body data of some kind, we permit white space; so always
      # read the body, then strip the white space from it.
      #
      # Start by reading only a limited amount of data. Then try to read more.
      # According the input stream documentation of the Rack specification:
      #
      #   http://rubydoc.info/github/rack/rack/master/file/SPEC
      #
      # ...then when we call "read" with a length value and there's no more
      # data to read, it should return nil. If it doesn't, the payload is
      # too big. Reject it.

      body = @request.body.read( MAXIMUM_PAYLOAD_SIZE )

      unless ( body.nil? || body.is_a?( String ) ) && @request.body.read( MAXIMUM_PAYLOAD_SIZE ).nil?
        return @response.add_error( 'platform.malformed',
                                    :message => 'Body data exceeds configured maximum size for platform' )
      end

      if action == :create || action == :update
        service_request.body = payload_to_hash( body )
        return @response.for_rack() if @response.halt_processing?

      elsif body.nil? == false && body.is_a?( String ) && body.strip.length > 0
        return @response.add_error( 'platform.malformed',
                                    :message => 'Unexpected body data for this action',
                                    :reference => { :action => action } )
      end

      # Finally - dispatch to service.

      context = ApiTools::ServiceContext.new(
        @session,
        service_request,
        @response
      )

      implementation.send( action, context )
    end

    # Run request preprocessing - common actions that occur after service
    # instance selection and service-specific processing.
    #
    # On exit, +@response+ may have been updated.
    #
    def postprocess

      # TODO: Nothing?
      #
      # This is only called on service *success*. Potentially we can hook in
      # the validation of the service's output (internal self-check) according
      # the expected returned Resource that the interface class defines (see
      # the "interface.resource" property), so long as it's defined in the
      # ApiTools::Data::Resources collection.
      #
      # The outgoing response body in the service response object is an Array
      # or Hash. We can check, for known resource types, the "language" of the
      # first item & set Content-Language, assuming an internationalised type.
      #
      # Can certainly make sure that we enforce all-call-resource-representation
      # here - for 200 cases, *all* calls should be returning a representation
      # or a list (even if the list is empty). That includes 'delete' ("here
      # is what I just deleted" - aids stack-like coding in clients).

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
      if SUPPORTED_MEDIA_TYPES.include?( @request.media_type ) &&
         SUPPORTED_ENCODINGS.include?( @request.content_charset )

         @content_type     = @request.media_type
         @content_encoding = @request.content_charset

      else

        @response.errors.add_error(
          'platform.malformed',
          :message => "Content-Type '#{ @request.content_type }' does not match supported types '#{ SUPPORTED_MEDIA_TYPES }' and/or encodings '#{ SUPPORTED_ENCODINGS }'"
        )

      end
    end

    # Preprocessing stage that sets up common headers required in any reseponse.
    # May vary according to inbound content type requested. If processing was
    # aborted early (e.g. missing inbound Content-Type) we may fall to defaults.
    #
    # (At the time of writing, platform documentations say we're JSON only - but
    # there's an strong chance of e.g. XML representation being demanded later).
    #
    def set_common_response_headers
      @response.add_header( 'Content-Type', "#{ @content_type || 'application/json' }; charset=#{ @content_encoding || 'utf-8' }" )
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

    # Safely parse the client payload in the context of the defined content
    # type (#check_content_type_header must have been run first). Pass the
    # body payload string.
    #
    def payload_to_hash( body )

      begin
        case @content_type
          when 'application/json'

            # We're aiming for Ruby 2.1 or later, but might end up on 1.9.
            #
            # https://www.ruby-lang.org/en/news/2013/02/22/json-dos-cve-2013-0269/
            #
            @payload_hash = JSON.parse( body, :create_additions => false )

        end

      rescue => e
        @payload_hash = {}
        @response.errors.add_error( 'generic.malformed' )

      end

      if @payload_hash.nil?
        raise "Internal error - content type '#{ @content_type }' is not supported here; \#check_content_type_header() should have caught that"
      end

      return @payload_hash
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

      [ remaining_path_components, extension || '' ]
    end

    # Process query string data for list actions. Only call if there's a list
    # action being requested.
    #
    # +query_string+::   The 'raw' query string from Rack.
    # +interface+::      Interface definition for the service being targeted.
    # +service_request:: An ApiTools::ServiceRequest instance. This will be
    #                    updated if successful with list parameter data.
    #
    # Returns +nil+ on success, else an error expressed as a Rack response
    # array - this can be passed directly back to Rack.
    #
    def process_query_string( query_string, interface, service_request )

      # The 'decode' call produces an array of two-element arrays, the first
      # being the key and next being the value, already CGI unescaped once.
      #
      # On some Ruby versions bad data here can cause an exception, so there's
      # a catch-all "rescue" at the end of the function to return a 'malformed'
      # response if necessary.

      query_data = URI.decode_www_form( query_string )
      query_hash = Hash[ query_data ]

      unrecognised_query_keys = query_hash.keys - ALLOWED_QUERIES
      malformed = unrecognised_query_keys unless unrecognised_query_keys.empty?

      unless malformed
        if query_hash.has_key?( 'limit' )
          limit     = ApiTools::Utilities::to_integer?( query_hash[ 'limit' ] )
          malformed = :limit if limit.nil?
        else
          limit = interface.to_list.limit.to_i
        end
      end

      unless malformed
        if query_hash.has_key?( 'offset' )
          offset    = ApiTools::Utilities::to_integer?( query_hash[ 'offset' ] )
          malformed = :offset if offset.nil?
        else
          offset = 0
        end
      end

      unless malformed
        sort_key = query_hash[ 'sort' ] || interface.to_list.default_sort_key
        malformed = :sort unless interface.to_list.sort.keys.include?( sort_key )
      end

      unless malformed
        direction = query_hash[ 'direction' ] || interface.to_list.sort[ sort_key ][ 0 ]
        malformed = :direction unless interface.to_list.sort[ sort_key ].include?( direction )
      end

      unless malformed
        search = query_hash[ 'search' ]
        unless search.nil?
          search = Hash[ URI.decode_www_form( search ) ]
          unrecognised_search_keys = search.keys - interface.to_list.search
          malformed = "search: #{ unrecognised_search_keys.join(', ') }" unless unrecognised_search_keys.empty?
        end
      end

      unless malformed
        filter = query_hash[ 'filter' ]
        unless filter.nil?
          filter = Hash[ URI.decode_www_form( filter ) ]
          unrecognised_filter_keys = filter.keys - interface.to_list.filter
          malformed = "filter: #{ unrecognised_filter_keys.join(', ') }" unless unrecognised_filter_keys.empty?
        end
      end

      unless malformed
        embeds = query_hash[ '_embed' ]
        unless embeds.nil?
          embeds = embeds.split( ',' )
          unrecognised_embeds = embeds - interface.embeds
          malformed = "_embed: #{ unrecognised_embeds.join(', ') }" unless unrecognised_embeds.empty?
        end
      end

      unless malformed
        references = query_hash[ '_reference' ]
        unless references.nil?
          references = references.split( ',' )
          unrecognised_references = references - interface.embeds # (sic.)
          malformed = "_reference: #{ unrecognised_references.join(', ') }" unless unrecognised_references.empty?
        end
      end

      if malformed
        return @response.add_error(
          'platform.malformed',
          :message => "One or more malformed or invalid query string parameters",
          :reference => { :including => malformed }
        )
      end

      service_request.list_offset         = offset
      service_request.list_limit          = limit
      service_request.list_sort_key       = sort_key
      service_request.list_sort_direction = direction
      service_request.list_search_data    = search
      service_request.list_filter_data    = filter
      service_request.embeds              = embeds
      service_request.references          = references

      return nil

    rescue
      return @response.add_error( 'platform.malformed' )

    end

  end
end
