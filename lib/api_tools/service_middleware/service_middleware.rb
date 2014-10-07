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
    ALLOWED_QUERIES_LIST = [
      'offset',
      'limit',
      'sort',
      'direction',
      'search',
      'filter'
    ]

    # Allowed common fields in query strings (all actions). Strings. Adds to
    # the ::ALLOWED_QUERIES_LIST for list actions.
    #
    # Only ever *add* to this list. As the API evolves, legacy clients will
    # be calling with previously documented query strings and removing any
    # entries from the list below could cause their requests to be rejected
    # with a 'platform.malformed' error.
    #
    ALLOWED_QUERIES_ALL = [
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

      # TODO: By now the resource, version and endpoint information is all
      #       known. This is where we'd tell a router, edge splitter or some
      #       other component about this instance as part of a wider
      #       configuration set that allowed inter-service communication.

      # TODO: If we can find out what port this thing is being served on (or
      #       determine we're under Alchemy), then we can dynamically note
      #       the endpoint and not have to hard-code development ports.

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

        log( :info )

        @response = ApiTools::ServiceResponse.new
        @session  = ApiTools::ServiceSession.new

        # TODO: Session validation/recovery, probably in preprocess()

        preprocess()
        process()     unless @response.halt_processing?
        postprocess() unless @response.halt_processing?

        return respond_with( @response.for_rack() )

      rescue => exception
        begin
          return respond_with( record_exception( @response, exception ) )

        rescue

          begin
            ApiTools::Logger.error(
              'ApiTools::ServiceMiddleware#call',
              'Middleware exception in exception handler',
              exception.to_s
            )
          rescue
            # Ignore logger exceptions. Can't do anything about them. Just
            # try and get the response back to the client now.
          end

          # An exception in the exception handler! Oh dear.
          #
          return [
            500, {}, Rack::BodyProxy.new( [ 'Middleware exception in exception handler' ] ) {}
          ]

        end
      end
    end

  private

    # Log that we're responding with the in the given Rack response def array,
    # returning the same, so that in #call the idiom can be:
    #
    #     return respond_with( ... )
    #
    # ...to log the response and return data to Rack all in one go.
    #
    # +rack_data+:: Rack response array (HTTP status code integer, header
    #               hash and body data as per Rack specification).
    #
    # Returns the +rack_data+ input parameter value without modifications.
    #
    def respond_with( rack_data )
      body = ''
      rack_data[ 2 ].each { | thing | body << thing.to_s }

      log(
        :info,
        'Responding with',
        rack_data[ 0 ],
        rack_data[ 1 ],
        body
      )

      return rack_data
    end

    # Log a message in a consistent way for middleware request processing.
    # Pass the log level and optional extra arguments which will be used as
    # strings that get appended to the log message.
    #
    # Before calling, +@request+ must be set up with the Rack::Request
    # instance for the call environment.
    #
    # +level+:: Log level. If +:info+ but +@response+ is present and indicates
    #           an error is being returned, then the level is automatically
    #           changed to +:warn+. If omitted, default is +:info+ (which may
    #           be promoted to +:warn+, as per previous sentence!).
    #
    # *args::   Optional extra arguments used as strings to add to log message.
    #
    def log( level = :info, *args )

      full_uri         = "Full URI: #{ @request.scheme }://#{ @request.host_with_port }/#{ @request.fullpath }"
      md5              = "Request MD5: #{ Digest::MD5.hexdigest( @request.env.to_s ) }"
      interaction_info = @interaction_id.nil? ? "No interaction ID yet" : "Interaction ID: #{ @interaction_id }"
      log_level        = :warn if log_level == :info && @response && @response.halt_processing?

      ApiTools::Logger.send(
        level,
        'ApiTools::ServiceMiddleware#call',
        full_uri,
        md5,
        interaction_info,
        *args
      )
    end

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

      process_query_string( action, @request.query_string, interface, service_request )
      return if @response.halt_processing?

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

      log(
        :info,
        "Raw body data read successfully: '#{ body }'"
      )

      if action == :create || action == :update
        service_request.body = payload_to_hash( body )
        return @response.for_rack() if @response.halt_processing?

      elsif body.nil? == false && body.is_a?( String ) && body.strip.length > 0
        return @response.add_error( 'platform.malformed',
                                    :message => 'Unexpected body data for this action',
                                    :reference => { :action => action } )
      end

      log(
        :info,
        "Dispatching with parsed body data: '#{ service_request.body }'"
      )

      # Finally - dispatch to service.

      context = ApiTools::ServiceContext.new(
        @session,
        service_request,
        @response,
        self
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

         @content_type     = @request.media_type.downcase
         @content_encoding = @request.content_charset.downcase

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
    # +action+::         Intended service action as a symbol, e.g. +:list+,
    #                    +:create+. Different actions may allow/prohibit
    #                    different things in the query string.
    # +query_string+::   The 'raw' query string from Rack.
    # +interface+::      Interface definition for the service being targeted.
    # +service_request:: An ApiTools::ServiceRequest instance. This will be
    #                    updated if successful with list parameter data.
    #
    # On exit, +@response+ will be updated, containing errors or deciphered
    # query data entered into attributes in the object.
    #
    def process_query_string( action, query_string, interface, service_request )

      # The 'decode' call produces an array of two-element arrays, the first
      # being the key and next being the value, already CGI unescaped once.
      #
      # On some Ruby versions bad data here can cause an exception, so there's
      # a catch-all "rescue" at the end of the function to return a 'malformed'
      # response if necessary.

      query_data = URI.decode_www_form( query_string )
      query_hash = Hash[ query_data ]

      allowed    = ALLOWED_QUERIES_ALL
      allowed   += ALLOWED_QUERIES_LIST if action == :list

      unrecognised_query_keys = query_hash.keys - allowed
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

    rescue
      @response.add_error( 'platform.malformed' )

    end

    # Record an exception in a given response object, overwriting any previous
    # error data if present.
    #
    # +response+::  The ApiTools::ServiceResponse object to record in; its
    #               ApiTools::ServiceResponse#errors collection is overwritten.
    #
    # +exception+:: The Exception instance to record.
    #
    # Returns the result of ApiTools::ServiceResponse#add_error.
    #
    def record_exception( response, exception )
      reference = {
        :exception => exception.message
      }

      unless self.class.environment.production? || self.class.environment.uat?
        reference[ :backtrace ] = exception.backtrace.join( " | " )
      end

      # A service can rewrite this field with a different object, leading
      # to an exception within the exception handler; so use a new one!
      #
      response.errors = ApiTools::Errors.new()

      return response.add_error(
        'platform.fault',
        :message => exception.message,
        :reference => reference
      )
    end

  protected

    # Is the given resource available as a local endpoint in this service
    # application?
    #
    # +resource+:: Resource name of interest, e.g. +:Purchase+. String or
    #              symbol.
    #
    # Returns an ApiTools::ServiceInterface instance if local, else +nil+.
    #
    def local_interface_for( resource )
      resource = resource.to_sym

      @services.find do | entry |
        entry.resource = resource
      end
    end

    # PROVISIONAL!
    #
    # Local development no-queue port allocations on an assumed physical
    # service grouping.
    #
    # +resource+:: Resource name of interest, e.g. +:Purchase+. String or
    #              symbol.
    #
    def development_port_for( resource )
      case resource.to_sym

        # Errors Service
        when :Errors
          3500

        # Financial Service
        when :Currency, :Balance, :Voucher, :Transaction
          3510

        # Programme API
        when :Participant, :Outlet, :Involvement, :Programme
          3520

        # Member API
        when :Account, :Member, :Membership, :MemberToken
          3530

        # Purchase API
        when :Purchase, :Refund, :Estimation, :Forecast, :Calculator
          3540

        # Utility API
        when :Version
          3550

        else
          9393
      end
    end

    # Perform an inter-service call. This shouldn't be called directly; call
    # via the ApiTools::ServiceMiddleware::ServiceEndpoint subclass specialised
    # methods instead, which makes sure it sets up the required parameters in
    # correct combinations. Undefined results will arise for incorrect calls.
    #
    # +interface+::   ApiTools::SerivceInterface to address or nil for
    #                 remote (non-local) call.
    # +http_method+:: HTTP method or equivalent, e.g. +:get+, +:delete+.
    # +ident+::       ID / UUID / similar; first and only path component.
    # +query_hash+::  Converted to query string.
    # +body_hash+::   Converted to body data.
    #
    # Parameters should be nil where the value would not be allowed given the
    # HTTP method. HTTP methods must map to understood actions.
    #
    # Returns an ApiTools::ServiceResponse describing the result of the call.
    #
    def inter_service( interface, http_method, ident, query_hash, body_hash )
      if ( interface.nil? )
        inter_service_remote( interface, http_method, ident, query_hash, body_hash )
      else
        inter_service_local( interface, http_method, ident, query_hash, body_hash )
      end
    end

    def inter_service_remote( interface, http_method, ident, query_hash, body_hash )
      host = port = nil

      unless self.class.environment.development? || self.class.environment.test?
        host = @request.host
        post = @request.port
      end

      host ||= '127.0.0.1'
      port ||= development_port_for( interface.resource )
      path   = "/v#{ interface.version }/#{ interface.endpoint }"
      path  << "/#{ ident }" unless ident.nil?

      unless query_hash.nil?
        query_hash = query_hash.dup
        query_hash[ :search ] = URI.encode_www_form( query_hash[ :search ] ) if ( query_hash[ :search ] ).is_a?( Hash )
        query_hash[ :filter ] = URI.encode_www_form( query_hash[ :filter ] ) if ( query_hash[ :filter ] ).is_a?( Hash )
      end

      # Grey area over whether this encodes spaces as "%20" or "+", but so
      # long as the middleware consistently uses the URI encode/decode calls,
      # it should work out in the end anyway.

      our_response = ApiTools::ServiceResponse.new

      begin
        uri = URI::HTTP.build( {
          :host  => host,
          :port  => port.to_i,
          :path  => path,
          :query => URI.encode_www_form( query_hash )
        } )

        remote_response = RestClient.send(
          http_method,
          uri.to_s,
          body_hash.nil? ? '' : body_hash.to_json
        )

        our_response.http_status_code = remote_response.code
        our_response.body             = JSON.parse( remote_response.to_str )

        remote_response.headers.each do | name, value |
          our_response.add_header( name, value, true )
        end

        # Since "our response" now has the decoded Hash payload, we use it
        # to see if there is error data there. If so, add it verbatim into
        # the errors collection.
        #
        if ( our_response.body[ 'kind' ] == 'Errors' )
          our_response.body[ 'errors' ].each do | error |
            our_response.add_precompiled_error( error )
          end
        end

      rescue => exception
        record_exception( our_response, exception )
      end

      return our_response
    end

    def inter_service_local( interface, http_method, indent, query_hash, body_hash )

    end

    # Representation of a callable service endpoint for a specific resource.
    # Services that wish to call other services should obtain an endpoint
    # instance via ApiTools::ServiceContext#endpoint then use the instance
    # methods described for this class to call other services. The calls they
    # use look very similar to the calls they implement for their own
    # instances. The response they get is in the form of an
    # ApiTools::ServiceResponse instance describing the inter-service call's
    # results.
    #
    class ServiceEndpoint < ApiTools::ServiceMiddleware

      # Create an endpoint instance on behalf of the given
      # ApiTools::ServiceMiddleware instance, directed at the given resource.
      #
      # +middleware_instance+:: ApiTools::ServiceMiddleware used to handle
      #                         onward requests.
      #
      # +resource+:: Resource name the endpoint targets, e.g. +:Purchase+.
      #              String or symbol.
      #
      def initialize( middleware_instance, resource )
        @middleware = middleware_instance
        @resource   = resource.to_s
        @interface  = @middleware.local_interface_for( @resource )
      end

      def list( query_hash )
        @middleware.inter_service(
          @interface,
          :get,
          nil,
          query_hash,
          nil
        )
      end

      def show( ident, query_hash )
        @middleware.inter_service(
          @interface,
          :get,
          nil,
          query_hash,
          body_hash
        )
      end

      def create( query_hash, body_hash )
        @middleware.inter_service(
          @interface,
          :post,
          nil,
          query_hash,
          body_hash
        )
      end

      def update( ident, query_hash, body_hash )
        @middleware.inter_service(
          @interface,
          :patch,
          ident,
          query_hash,
          body_hash
        )
      end

      def delete( ident, query_hash )
        @middleware.inter_service(
          @interface,
          :patch,
          ident,
          query_hash,
          body_hash
        )
      end

    end # 'class ServiceEndpoint'
  end   # 'class ServiceMiddleware'
end     # 'module ApiTools'
