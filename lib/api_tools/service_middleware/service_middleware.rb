########################################################################
# File::    service_middleware.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Rack middleware, declared in a +config.ru+ file in the usual
#           way - "use( ApiTools::ServiceMiddleware )".
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
#           16-Oct-2014 (TC):  Added Session Code.
#           11-Nov-2014 (ADH): Some internal classes split out into
#                              their own files to reduce file size here.
########################################################################

require 'drb/drb'
require "net/http"
require "uri"

module ApiTools

  # Rack middleware, declared in (e.g.) a +config.ru+ file in the usual way:
  #
  #      use( ApiTools::ServiceMiddleware )
  #
  # This is the core of the common service implementation on the Rack
  # client-request-handling side. It is run in the context of an
  # ApiTools::ServiceApplication subclass that's been given to Rack as the Rack
  # endpoint application; it looks at the component interfaces supported by the
  # service and routes requests to the correct one (or raises a 404).
  #
  # Lots of preprocessing and postprocessing gets done to set up things like
  # locale information, enforce content types and so-forth. Request data is
  # assembled in a parsed, structured format for passing to service
  # implementations and a response object built so that services have a
  # consistent way to return results, which can be post-processed further by
  # the middleware before returning the data to Rack.
  #
  # The middleware supports structured logging - see ApiTools::Logger::report.
  # Its own log data uses component +Middleware+. It will also log essential
  # data for successful and failed interactions with resource endpoints using
  # the resource name as the component. In such cases, the codes it uses are
  # always prefixed by +middleware_+ and service applications should consider
  # codes with this prefix reserved - do not use such codes yourself.
  #
  class ServiceMiddleware

    ApiTools::Logger.logger = ApiTools::ServiceMiddleware::StructuredLogger

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
      '_reference'
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

    # Do we have Memcache available? If not, assume local development with
    # higher level queue services not available. Most service authors should
    # not ever need to check this.
    #
    def self.has_memcache?
      m = ENV[ 'MEMCACHE_URL' ]
      m.nil? == false && m.empty? == false
    end

    # Are we running on the queue, else (implied) a local HTTP server?
    #
    def self.on_queue?
      q = ENV[ 'AMQ_ENDPOINT' ]
      q.nil? == false && q.empty? == false
    end

    # Record internally the HTTP host and port during local development via
    # e.g +rackup+ or testing with rspec. This is usually not called directly
    # except via the Rack startup monkey patch code in
    # +rack_monkey_patch.rb+.
    #
    # Options hash +:Host+ and +:Port+ entries are recorded.
    #
    def self.record_host_and_port( options = {} )
      @@recorded_host = options[ :Host ]
      @@recorded_port = options[ :Port ]
    end

    # Initialize the middleware instance.
    #
    # +app+ Rack app instance to which calls should be passed.
    #
    def initialize( app )

      @service_container = app

      if defined?( NewRelic ) &&
         defined?( NewRelic::Agent ) &&
         defined?( NewRelic::Agent::Instrumentation ) &&
         defined?( NewRelic::Agent::Instrumentation::MiddlewareProxy ) &&
         @service_container.is_a?( NewRelic::Agent::Instrumentation::MiddlewareProxy )

        if @service_container.respond_to?( :target )
          @newrelic_wrapper  = @service_container
          @service_container = @service_container.target()
        else
          raise "ApiTools::ServiceMiddleware instance created with NewRelic-wrapped ServiceApplication entity, but NewRelic API is not as expected by ApiTools; incompatible NewRelic version."
        end
      end

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
          raise "ApiTools::ServiceMiddleware encountered invalid interface class #{ interface } via service class #{ @service_container.class }"
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
          :path           => "/v#{ interface.version }/#{ interface.endpoint }",
          :interface      => interface,
          :implementation => interface.implementation.new
        }

      end

      announce_presence_of( @services )
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

        @interaction_id = @session_id = nil
        @rack_request   = Rack::Request.new( env )

        # If running on Alchemy / an AMQP based architecture, it'll have
        # forwarded details of the AMQEndpoint gem's queue service via the
        # Rack environment. Send this to the structured logger so it can do
        # queue-based structured logging via the provided service.
        #
        ApiTools::ServiceMiddleware::StructuredLogger.alchemy = env[ 'rack.alchemy' ] || env[ 'alchemy' ]

        debug_log()

        @service_response = ApiTools::ServiceResponse.new

        preprocess()
        process()     unless @service_response.halt_processing?
        postprocess() unless @service_response.halt_processing?

        return respond_with( @service_response.for_rack() )

      rescue => exception
        begin
          return respond_with( record_exception( @service_response, exception ) )

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

      id   = nil
      body = ''

      rack_data[ 2 ].each { | thing | body << thing.to_s }

      if @service_response.halt_processing?
        begin
          # Error cases should be infrequent, so we can "be nice" and re-parse
          # the returned body for structured logging only. We don't do this for
          # successful responses as we assume those will be much more frequent
          # and the extra parsing step would be heavy overkill for a log.
          #
          # This also means we can (in theory) extract the intended resource
          # UUID and include that in structured log data to make sure any
          # persistence layers store the item as an error with the correct ID.

          body = JSON.parse( body )
          id   = body[ 'id' ]
        rescue
        end

        level = :error

      else
        body  = body[ 0 .. 1023 ] << '...' if ( body.size > 1024 )
        level = :info

      end

      data = {
        :interaction_id => @interaction_id,
        :payload        => {
          :http_status_code => rack_data[ 0 ],
          :http_headers     => rack_data[ 1 ],
          :response_body    => body
        }
      }

      data[ :id      ] = id unless id.nil?
      data[ :session ] = @service_session.to_h unless @service_session.nil?

      ApiTools::Logger.report(
        level,
        :Middleware,
        :outbound,
        data
      )

      return rack_data
    end

    # This is part of the formalised structured logging interface upon which
    # external entites might depend. Change with care.
    #
    # For a given service interface, an implementation of which is receiving
    # a given action under the given request context, log the response *after
    # the fact* of calling the implementation, using the target interface's
    # resource name for the structured log entry's "component" field.
    #
    # +interface+::      The ApiTools::ServiceInterface subclass referring to
    #                    the service implementation that was called.
    #
    # +action+::         Name of method that was called in the service instance
    #                    as a Symbol, e.g. :list, :show.
    #
    # +context+::        ApiTools::ServiceContext instance containing request
    #                    and response details.
    #
    def auto_log( interface, action, context )

      # Data as per ApiTools::ServiceMiddleware::StructuredLogger.

      data = {
        :interaction_id => @interaction_id,
        :session        => @service_session.to_h
      }

      if ( context.response.halt_processing? )
        log_level   = :error
        code        = "middleware_error_#{ action }"
        data[ :id ] = context.response.errors.uuid
      else
        log_level   = :info
        code        = "middleware_#{ action }"
      end

      # Don't bother logging list responses - they could be huge - instead log
      # all list-related parameters from the inbound request.

      if context.response.body.is_a?( ::Array )
        attributes       = %i( list_offset list_limit list_sort_key list_sort_direction list_search_data list_filter_data embeds references )
        data[ :payload ] = {}

        attributes.each do | attribute |
          data[ attribute ] = context.request.send( attribute )
        end
      else
        data[ :payload ] = context.response.body
      end

      ApiTools::Logger.report(
        log_level,
        interface.resource,
        code,
        data
      )
    end

    # Log a debug message. Pass optional extra arguments which will be used as
    # strings that get appended to the log message.
    #
    # Before calling, +@rack_request+ must be set up with the Rack::Request
    # instance for the call environment.
    #
    # *args:: Optional extra arguments used as strings to add to log message.
    #
    def debug_log( *args )
      ApiTools::Logger.report(
        :debug,
        :Middleware,
        :log,
        {
          :full_uri       => "#{ @rack_request.scheme }://#{ @rack_request.host_with_port }#{ @rack_request.fullpath }",
          :interaction_id => @interaction_id,
          :payload        => { 'args' => args }
        }
      )
    end

    # Announce the presence of the service endpoints to known interested
    # parties.
    #
    # +services+:: Array of Hashes describing service information.
    #
    # Hash keys/values are as follows:
    #
    # +regexp+::         A regular expression for a URI path which, if matched,
    #                    means that this service endpoint is being called.
    # +path+::           The endpoint path that the regexp would match, with
    #                    leading "/" (e.g. "/v1/products")
    # +interface+::      The ServiceInterface subclass for this endpoint.
    # +implementation+:: The ServiceImplementation subclass instance for this
    #                    endpoint.
    #
    def announce_presence_of( services )

      if ! self.class.environment.test? && self.class.on_queue?

        # Queue-based announcement goes here

      else

        # Rack provides no formal way to find out our host or port before a
        # request arrives, because in part it might change due to clustering.
        # For local development on an assumed single instance server, we can
        # ask Ruby itself for all Rack::Server instances, expecting just one.
        # If there isn't just one, we rely on the Rack monkey patch or a
        # hard coded default.

        host    = nil
        port    = nil
        servers = ObjectSpace.each_object( Rack::Server )

        if servers.count == 1
          server = servers.first
          host   = server.options[ :Host ]
          port   = server.options[ :Port ]
        end

        host = @@recorded_host if host.nil? && defined?( @@recorded_host )
        port = @@recorded_port if port.nil? && defined?( @@recorded_port )

        host ||= '127.0.0.1'
        port ||= 9292

        # URI for DRb server used during local machine development as a registry
        # of service endpoints. Whichever service starts first runs the server
        # which others connect to if subsequently started.
        #
        # Use IP address, rather than 'localhost' here, to ensure that "address
        # in use" errors are raised immediately if a second server startup
        # attempt is made:
        #
        #   https://bugs.ruby-lang.org/issues/3052
        #
        drb_uri = "druby://127.0.0.1:#{ ENV[ 'APITOOLS_MIDDLEWARE_DRB_PORT_OVERRIDE' ] || 8787 }"

        # Start the DRb server, or connect to it if already running.
        #
        begin
          DRb.start_service( drb_uri, FRONT_OBJECT )
          @drb_service = DRbObject.new_with_uri( drb_uri )
        rescue Errno::EADDRINUSE => e
          DRb.start_service
          @drb_service = DRbObject.new_with_uri( drb_uri )
        end

        # Announce our local services.
        #
        services.each do | service |
          interface = service[ :interface ]

          @drb_service.add(
            interface.resource,
            interface.version,
            "http://#{ host }:#{ port }#{ service[ :path ] }"
          )
        end
      end
    end

    # Load Session from memcache and decode it.
    #
    # On exit, +@service_session+ and +@session_id+ will have been updated. Be
    # sure to check +@service_response.halt_processing?+ to see if processing
    # should abort and return immediately.
    #
    def load_session
      @session_id = @rack_request.env[ 'HTTP_X_SESSION_ID' ]

      # Use test mode for sessions if in a test environment or if there is
      # no configured MemCache available (assume local development).

      environment = self.class.environment()
      ApiTools::ServiceSession.testing( environment.test? || ! self.class.has_memcache? )

      @service_session = ApiTools::ServiceSession.load_session(
        ENV[ 'MEMCACHE_URL' ],
        @session_id,
      )

      if @service_session.nil?
        return @service_response.add_error( 'platform.invalid_session' )
      end
    end

    # Run request preprocessing - common actions that occur prior to any service
    # instance selection or service-specific processing.
    #
    # On exit, +@service_response+ may have been updated. Be sure to check
    # +@service_response.halt_processing?+ to see if processing should abort
    # and return immediately.
    #
    def preprocess


      # =======================================================================
      # Additions here may require corresponding additions to the inter-service
      # local call code.
      # =======================================================================


      check_content_type_header()

      @locale         = deal_with_language_header()
      @interaction_id = find_or_generate_interaction_id()

      ApiTools::Logger.report(
        :info,
        :Middleware,
        :inbound,
        {
          :interaction_id => @interaction_id,
          :payload        => @rack_request.env
        }
      )

      set_common_response_headers( @service_response )
      load_session()
    end

    # Process the client's call. The heart of service routing and application
    # invocation. Relies entirely on data assembled during initialisation of
    # this middleware instance or during handling in #call.
    #
    def process


      # =======================================================================
      # Additions here may require corresponding additions to the inter-service
      # local call code.
      # =======================================================================


      # Select a service based on the escaped URI's path. If we find none,
      # then there's no matching endpoint; badly routed request; 404. If we
      # find many, raise an exception and rely on the exception handler to
      # send back a 500.

      uri_path = CGI.unescape( @rack_request.path() )

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
        return @service_response.add_error(
          'platform.not_found',
          'reference' => { :entity_name => '' }
        )
      elsif selected_services.size > 1
        raise "Multiple service endpoint matches - internal server configuration fault"
      else
        selected_service = selected_services[ 0 ]
      end

      uri_path_components, uri_path_extension = @path_data
      interface                               = selected_service[ :interface      ]
      implementation                          = selected_service[ :implementation ]

      update_service_response_for( @service_response, interface )

      # Check for a supported action.

      action = determine_action(
        interface,
        @rack_request.request_method,
        uri_path_components.empty?,
        @service_response
      )

      return if @service_response.halt_processing?

      # Looks good so far, so allocate a request object to pass on to the
      # interface and hold other higher level parsed data assembled below.

      service_request                     = new_service_request_for( interface )
      service_request.uri_path_components = uri_path_components
      service_request.uri_path_extension  = uri_path_extension

      # There should only be a query string for GET methods that ask for lists
      # of resources.

      process_query_string(
        action,
        @rack_request.query_string,
        interface,
        service_request,
        @service_response
      )

      return if @service_response.halt_processing?

      # There should be no spurious path data for "list" or "create" actions -
      # only "show", "update" and "delete" take extra data via the URL's path.
      # Conversely, other actions require it.

      if action == :list || action == :create
        return @service_response.add_error( 'platform.malformed',
                                            'message' => 'Unexpected path components for this action',
                                            'reference' => { :action => action } ) unless uri_path_components.empty?
      else
        return @service_response.add_error( 'platform.malformed',
                                            'message' => 'Expected path components identifying target resource instance for this action',
                                            'reference' => { :action => action } ) if uri_path_components.empty?
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

      body = @rack_request.body.read( MAXIMUM_PAYLOAD_SIZE )

      unless ( body.nil? || body.is_a?( ::String ) ) && @rack_request.body.read( MAXIMUM_PAYLOAD_SIZE ).nil?
        return @service_response.add_error( 'platform.malformed',
                                            'message' => 'Body data exceeds configured maximum size for platform' )
      end

      debug_log( "Raw body data read successfully: '#{ body }'" )

      if action == :create || action == :update
        service_request.body = payload_to_hash( body )
        return @service_response.for_rack() if @service_response.halt_processing?

      elsif body.nil? == false && body.is_a?( ::String ) && body.strip.length > 0
        return @service_response.add_error( 'platform.malformed',
                                            'message' => 'Unexpected body data for this action',
                                            'reference' => { :action => action } )
      end

      debug_log( "Dispatching with parsed body data: '#{ service_request.body }'" )

      # Finally - dispatch to service.

      context = ApiTools::ServiceContext.new(
        @service_session,
        service_request,
        @service_response,
        self
      )

      dispatch_to( interface, implementation, action, context )
    end

    # Dispatch a call to the given implementation, with before/after actions.
    #
    # +interface+::      The ApiTools::ServiceInterface subclass referring
    #                    to the implementation class of which an instance is
    #                    given in the +implementation+ parameter.
    #
    # +implementation+:: ApiTools::ServiceImplementation subclass instance to
    #                    call.
    #
    # +action+::         Name of method to call in that instance as a Symbol,
    #                    e.g. :list, :show.
    #
    # +context+::        ApiTools::ServiceContext instance to pass to the
    #                    named action method as the sole input parameter.
    #
    def dispatch_to( interface, implementation, action, context )

      # TODO:
      #   https://trello.com/c/Z4qu2mGv/20-revisit-activerecord-is-connection-active-recovery
      #
      # then:
      #
      #   https://github.com/socialcast/resque-ensure-connected/issues/3
      #
      # and class ConnectionManagement in:
      #   https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/abstract/connection_pool.rb
      #
      if ( defined?( ActiveRecord ) &&
           defined?( ActiveRecord::Base ) &&
           ActiveRecord::Base.respond_to?( :clear_active_connections! ) )
        ActiveRecord::Base.clear_active_connections!
      end

      implementation.before( context ) if implementation.respond_to?( :before )
      implementation.send( action, context ) unless context.response.halt_processing?
      implementation.after( context ) if ! context.response.halt_processing? and implementation.respond_to?( :after )

      auto_log( interface, action, context )
    end

    # Run request preprocessing - common actions that occur after service
    # instance selection and service-specific processing.
    #
    # On exit, +@service_response+ may have been updated.
    #
    def postprocess


      # =======================================================================
      # Additions here may require corresponding additions to the inter-service
      # local call code.
      # =======================================================================


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
      content_type      = @rack_request.media_type
      content_encoding  = @rack_request.content_charset

      @content_type     = content_type.nil?     ? nil : content_type.downcase
      @content_encoding = content_encoding.nil? ? nil : content_encoding.downcase

      unless SUPPORTED_MEDIA_TYPES.include?( @content_type ) &&
             SUPPORTED_ENCODINGS.include?( @content_encoding )

        @service_response.errors.add_error(
          'platform.malformed',
          'message' => "Content-Type '#{ @rack_request.content_type }' does not match supported types '#{ SUPPORTED_MEDIA_TYPES }' and/or encodings '#{ SUPPORTED_ENCODINGS }'"
        )

      end
    end

    # Extract the +Content-Language+ header value from the client, or if that
    # is missing, +Accept-Language+. Returns it, or a default of "en-nz",
    # converted to lower case.
    #
    # We support neither a list of preferences nor "qvalues", so if there is
    # a list, we only take the first item; if there is a qvalue, we strip it
    # leaving just the language part, e.g. "en-gb".
    #
    def deal_with_language_header
      lang = @rack_request.env[ 'HTTP_CONTENT_LANGUAGE' ]
      lang = @rack_request.env[ 'HTTP_ACCEPT_LANGUAGE' ] if lang.nil? || lang.empty?

      unless lang.nil? || lang.empty?
        # E.g. "Accept-Language: da, en-gb;q=0.8, en;q=0.7" => 'da'
        lang = lang.split( ',' )[ 0 ]
        lang = lang.split( ';' )[ 0 ]
      end

      lang = 'en-nz' if lang.nil? || lang.empty?
      lang.downcase
    end

    # Find the value of an X-Interaction-ID header (if one is already present)
    # or generate a new Interaction ID and store the result for the response,
    # as a new X-Interaction-ID header.
    #
    def find_or_generate_interaction_id
      iid = @rack_request.env[ 'HTTP_X_INTERACTION_ID' ]
      iid = ApiTools::UUID.generate() if iid.nil? || iid == ''

      @service_response.add_header( 'X-Interaction-ID', iid )

      iid
    end

    # Preprocessing stage that sets up common headers required in any response.
    # May vary according to inbound content type requested. If processing was
    # aborted early (e.g. missing inbound Content-Type) we may fall to defaults.
    #
    # (At the time of writing, platform documentations say we're JSON only - but
    # there's an strong chance of e.g. XML representation being demanded later).
    #
    # +response+:: ApiTools::ServiceResponse instance to update.
    #
    def set_common_response_headers( response )
      response.add_header( 'Content-Type', "#{ @content_type || 'application/json' }; charset=#{ @content_encoding || 'utf-8' }" )
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

    # Determine the action to call in a service for the given inbound HTTP
    # method.
    #
    # +interface+::       ApiTools::ServiceInterface for which the call is
    #                     being made.
    # +http_method+::     Inbound method as a string, e.g. +'POST'+
    # +get_is_list+::     If +true+, treat GET methods as +:list+, else as
    #                     +:show+. This is often determined on the basis
    #                     of e.g. path components after the endpoint part
    #                     of the URI path being absent or present.
    # +response+::        ApiTools::ServiceResponse instance that will be
    #                     updated with an error if the HTTP method does not
    #                     map to an allowed action.
    #
    # Returns the action as a symbol (e.g. +:list+) unless there is an error.
    # If the ApiTools::ServiceResponse#halt_processing? result for the given
    # +response+ parameter is +true+ then the returned value is invalid as
    # the service does not support the action; +response+ has already been
    # updated with an appropriate error.
    #
    def determine_action( interface, http_method, get_is_list, response )

      http_method     = ( http_method || '' ).upcase
      allowed_actions = interface.actions || ALLOWED_ACTIONS

      # Clumsy code because there is no 1:1 map from HTTP method to action
      # (e.g. GET can be :show or :list).
      #
      action = case http_method
        when 'POST'
          :create
        when 'PATCH'
          :update
        when 'DELETE'
          :delete
        when 'GET'
          get_is_list ? :list : :show
      end

      unless allowed_actions.include?( action )
        response.add_error(
          'platform.method_not_allowed',
          'message' => "Service endpoint '/v#{ interface.version }/#{ interface.endpoint }' does not support HTTP method '#{ http_method }' yielding action '#{ action }'"
        )
      end

      return action
    end

    # Update a ApiTools::ServiceResponse instance for making a call to
    # the given ApiTools::ServiceInterface, setting up error description
    # information. Other initialisation is left to the caller.
    #
    # +response+::  ApiTools::ServiceResponse instance to update.
    # +interface+:: ApiTools::ServiceInterface for which the request is being
    #               constructed. Custom error descriptions from that
    #               interface, if any, are included in the response object's
    #               error collection data.
    #
    def update_service_response_for( response, interface )
      unless interface.errors_for.nil?
        response.errors = ApiTools::Errors.new( interface.errors_for )
      end
    end

    # Returns a new ApiTools::ServiceRequest instance for making a call to
    # the given ApiTools::ServiceInterface, setting up locale information.
    # Other initialisation is left to the caller.
    #
    # +interface+:: ApiTools::ServiceInterface for which the request is being
    #               constructed.
    #
    def new_service_request_for( interface )
      request        = ApiTools::ServiceRequest.new
      request.locale = @locale

      return request
    end

    # Process query string data for list actions. Only call if there's a list
    # action being requested.
    #
    # +action+::          Intended service action as a symbol, e.g. +:list+,
    #                     +:create+. Different actions may allow/prohibit
    #                     different things in the query string.
    # +query_string+::    The 'raw' query string from Rack.
    # +interface+::       Interface definition for the service being targeted.
    # +service_request::  An ApiTools::ServiceRequest instance. This will be
    #                     updated if successful with list parameter data.
    # +service_response:: An ApiTools::ServiceResponse instance. This will be
    #                     updated if unsuccessful with error data.
    #
    # On exit, +service_response+ will be updated with errors or
    # +service_request+ will have deciphered query data entered into
    # attributes in the object.
    #
    def process_query_string( action, query_string, interface, service_request, service_response )

      # The 'decode' call produces an array of two-element arrays, the first
      # being the key and next being the value, already CGI unescaped once.
      #
      # On some Ruby versions bad data here can cause an exception, so there's
      # a catch-all "rescue" at the end of the function to return a 'malformed'
      # response if necessary.

      query_data = URI.decode_www_form( query_string )
      query_hash = Hash[ query_data ]

      str                       = query_hash[ 'search' ]
      query_hash[ 'search' ]    = Hash[ URI.decode_www_form( str ) ] unless str.nil?

      str                       = query_hash[ 'filter' ]
      query_hash[ 'filter' ]    = Hash[ URI.decode_www_form( str ) ] unless str.nil?

      str                       = query_hash[ '_embed' ]
      query_hash[ '_embed']     = str.split( ',' ) unless str.nil?

      str                       = query_hash[ '_reference' ]
      query_hash[ '_reference'] = str.split( ',' ) unless str.nil?

      return process_query_hash(
               action,
               query_hash,
               interface,
               service_request,
               service_response
             )
    end

    # Process a hash of URI-decoded form data in the same way as
    # #process_query_string (and used as a back-end for that). Nested search
    # and filter strings should be decoded as nested hashes. Nested _embed and
    # _reference lists should be stored as arrays. Keys and values must be
    # Strings.
    #
    # +action+::           See #process_query_string.
    # +query_hash+::       Hash of data derived from query string.
    # +interface+::        See #process_query_string.
    # +service_request+::  See #process_query_string.
    # +service_response+:: See #process_query_string.
    #
    # On exit, +service_response+ will be updated with errors or
    # +service_request+ will have deciphered query data entered into
    # attributes in the object.
    #
    def process_query_hash( action, query_hash, interface, service_request, service_response )
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
        search = query_hash[ 'search' ] || {}

        unrecognised_search_keys = search.keys - ( interface.to_list.search || [] )
        malformed = "search: #{ unrecognised_search_keys.join(', ') }" unless unrecognised_search_keys.empty?
      end

      unless malformed
        filter = query_hash[ 'filter' ] || {}

        unrecognised_filter_keys = filter.keys - ( interface.to_list.filter || [] )
        malformed = "filter: #{ unrecognised_filter_keys.join(', ') }" unless unrecognised_filter_keys.empty?
      end

      unless malformed
        embeds = query_hash[ '_embed' ] || []

        unrecognised_embeds = embeds - ( interface.embeds || [] )
        malformed = "_embed: #{ unrecognised_embeds.join(', ') }" unless unrecognised_embeds.empty?
      end

      unless malformed
        references = query_hash[ '_reference' ] || []

        unrecognised_references = references - ( interface.embeds || [] )# (sic.)
        malformed = "_reference: #{ unrecognised_references.join(', ') }" unless unrecognised_references.empty?
      end

      return service_response.add_error(
        'platform.malformed',
        'message' => "One or more malformed or invalid query string parameters",
        'reference' => { :including => malformed }
      ) if malformed

      service_request.list_offset         = offset
      service_request.list_limit          = limit
      service_request.list_sort_key       = sort_key
      service_request.list_sort_direction = direction
      service_request.list_search_data    = search
      service_request.list_filter_data    = filter
      service_request.embeds              = embeds
      service_request.references          = references
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
        @service_response.errors.add_error( 'generic.malformed' )

      end

      if @payload_hash.nil?
        raise "Internal error - content type '#{ @content_type }' is not supported here; \#check_content_type_header() should have caught that"
      end

      return @payload_hash
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
        'message' => exception.message,
        'reference' => reference
      )
    end

  protected

    # Is the given resource available as a local endpoint in this service
    # application?
    #
    # +resource+:: Resource name of interest, e.g. +:Purchase+. String or
    #              symbol.
    #
    # +version+::  Version of interface required as an Integer. Optional -
    #              default is 1.
    #
    # Returns an @services entry (see implementation of #initialize) if local,
    # else +nil+.
    #
    def local_service_for( resource, version = 1 )
      resource = resource.to_sym
      version  = version.to_i

      @services.find do | entry |
        interface = entry[ :interface ]
        interface.resource == resource && interface.version == version
      end
    end

    # Is the given resource available as a remote endpoint we can target via
    # HTTP?
    #
    # +resource+:: Resource name of interest, e.g. +:Purchase+. String or
    #              symbol.
    #
    # +version+::  Version of interface required as an Integer. Optional -
    #              default is 1.
    #
    # Returns a URI as a string if an endpoint is found, else +nil+.
    #
    def remote_service_for( resource, version = 1 )
      begin
        @drb_service.find( resource, version )
      rescue
        nil
      end
    end

    # Perform an inter-service call. This shouldn't be called directly; call
    # via the ApiTools::ServiceMiddleware::ServiceEndpoint subclass specialised
    # methods instead, which makes sure it sets up the required parameters in
    # correct combinations. Undefined results will arise for incorrect calls.
    #
    # +options+:: Options hash with keys and required values described below.
    #
    # Options are as follows - keys must be Symbols:
    #
    # +local+::       A +@services+ entry (see implementation of #initialize)
    #                 describing the service to call if local, else +nil+ or
    #                 absent.
    # +remote+::      A URI as a String for a remote service endpoint, else
    #                 +nil+ or absent.
    # +resource+::    The String or Symbol resource name, e.g. "Product".
    # +version+::     The Integer endpoint API version, e.g. 2.
    # +http_method+:: HTTP method as a String, e.g. "+GET+", "+DELETE+".
    # +ident+::       ID / UUID / similar; first and only path component.
    # +query_hash+::  Converted to query string.
    # +body_hash+::   Converted to body data.
    #
    # Parameters should be nil where the value would not be allowed given the
    # HTTP method. HTTP methods must map to understood actions.
    #
    # @service_response is updated on exit. If this says "halt processing",
    # errors were generated. Ignore the function return value. Otherwise,
    # returns a Has equivalent of the JSON resource representation in the
    # non-list-action cases, else an array of zero or more JSON resource
    # representations in the list action case.
    #
    def inter_service( options )

      remote = options[ :local ].nil?

      debug_log( "#{ remote ? 'Remote' : 'Local' } inter-service call requested with options #{ options }" )

      if ( remote )
        result = inter_service_remote( options )
      else
        result = inter_service_local( options )
      end

      if @service_response.halt_processing?
        debug_log( "#{ remote ? 'Remote' : 'Local' } inter-service call halted processing with errors #{ @service_response.errors.errors }" )
      else
        debug_log( "#{ remote ? 'Remote' : 'Local' } inter-service call succeeded with result '#{ result }'" )
      end

      return result
    end

    # Make a remote (HTTP) inter-service call. Slow.
    #
    # +options+:: See #inter_service.
    #
    # Returns:: See #inter_service.
    #
    def inter_service_remote( options )
      remote_uri  = options[ :remote      ]
      http_method = options[ :http_method ]
      ident       = options[ :ident       ]
      body_hash   = options[ :body_hash   ]
      query_hash  = options[ :query_hash  ]

      # Add a 404 error to the response (via a Proc for internal reuse).

      add_404 = Proc.new {
        @service_response.add_error(
          'platform.not_found',
          'reference' => { :entity_name => "v#{ options[ :version ] } of #{ options[ :resource ] } interface endpoint" }
        )
      }

      # No endpoint found? Yikes!

      if ( remote_uri.nil? )
        return add_404.call()

      else
        remote_uri << "/#{ URI::escape( ident ) }" unless ident.nil?

      end

      # Grey area over whether this encodes spaces as "%20" or "+", but so
      # long as the middleware consistently uses the URI encode/decode calls,
      # it should work out in the end anyway.

      unless query_hash.nil?
        query_hash = query_hash.dup
        query_hash[ 'search' ] = URI.encode_www_form( query_hash[ 'search' ] ) if ( query_hash[ 'search' ].is_a?( ::Hash ) )
        query_hash[ 'filter' ] = URI.encode_www_form( query_hash[ 'filter' ] ) if ( query_hash[ 'filter' ].is_a?( ::Hash ) )

        query_hash[ '_embed'     ] = query_hash[ '_embed'     ].join( ',' ) if ( query_hash[ '_embed'     ].is_a?( ::Array ) )
        query_hash[ '_reference' ] = query_hash[ '_reference' ].join( ',' ) if ( query_hash[ '_reference' ].is_a?( ::Array ) )

        query_hash.delete( 'search'     ) if query_hash[ 'search'     ].nil? || query_hash[ 'search'     ].empty?
        query_hash.delete( 'filter'     ) if query_hash[ 'filter'     ].nil? || query_hash[ 'filter'     ].empty?
        query_hash.delete( '_embed'     ) if query_hash[ '_embed'     ].nil? || query_hash[ '_embed'     ].empty?
        query_hash.delete( '_reference' ) if query_hash[ '_reference' ].nil? || query_hash[ '_reference' ].empty?
      end

      unless query_hash.nil? || query_hash.empty?
        remote_uri << '?' << URI.encode_www_form( query_hash )
      end

      body_data = body_hash.nil? ? '' : body_hash.to_json
      headers   = {
        'Content-Type'     => 'application/json; charset=utf-8',
        'Content-Language' => @locale,
        'X-Interaction-ID' => @interaction_id || '+',
        'X-Session-ID'     => @session_id     || '+'
      }

      # Drive the HTTP library using the data assembled above

      remote_uri = URI.parse( remote_uri )
      http       = Net::HTTP.new( remote_uri.host, remote_uri.port )

      request_class = {
        'POST'   => Net::HTTP::Post,
        'PATCH'  => Net::HTTP::Patch,
        'DELETE' => Net::HTTP::Delete
      }[ http_method ] || Net::HTTP::Get

      request      = request_class.new( remote_uri.request_uri() )
      request.body = body_data unless body_data.empty?

      request.initialize_http_header( headers )

      begin
        response = http.request( request )
      rescue Errno::ECONNREFUSED => e
        return add_404.call()
      end

      # Parse the response (assumed valid JSON else #for_rack would have failed
      # when the originating response object was turned into the Rack response).

      parsed = JSON.parse( response.body )

      # Deal with headers sent in the call.

      ignores = Set.new( [

        # These are standard and automatic anyway

        'content-type',
        'content-language',
        'x-interaction-id',
        'x-session-id',

        # These can be set by HTTP operations and we're not interested in them

        'content-length',
        'server',
        'date',
        'connection'

      ] )

      response.each_header do | name, value |
        @service_response.add_header( name, value, true ) unless ignores.include?( name )
      end

      # Since "parsed" now has the decoded Hash payload, we use it to see if
      # there is error data there. If so, add it verbatim into the local errors
      # collection. Attempt to carry over the remote call's HTTP status code.

      if response.code.to_i > 299
        @service_response.http_status_code = response.code
      end

      if ( parsed[ 'kind' ] == 'Errors' )
        parsed[ 'errors' ].each do | error |
          @service_response.add_precompiled_error(
            error[ 'code'      ],
            error[ 'message'   ],
            error[ 'reference' ],
            response.code
          )
        end
      end

      # If the parsed data wrapped an array, extract just the array part.

      if ( parsed[ '_data' ].is_a?( ::Array ) )
        parsed = parsed[ '_data' ]
      end

      return parsed
    end

    # Make a local (non-HTTP local Ruby method call) inter-service call. Fast.
    #
    # +options+:: See #inter_service.
    #
    # Returns:: See #inter_service.
    #
    def inter_service_local( options )
      service        = options[ :local       ]
      http_method    = options[ :http_method ]
      ident          = options[ :ident       ]
      body_hash      = options[ :body_hash   ]
      query_hash     = options[ :query_hash  ]

      interface      = service[ :interface      ]
      actions        = service[ :actions        ]
      implementation = service[ :implementation ]

      # We must construct a call context for the local service. This means
      # a local request object which we fill in with data just as if we'd
      # parsed an inbound HTTP request and a response object that contains
      # the usual default data.

      local_service_response = ApiTools::ServiceResponse.new
      set_common_response_headers( local_service_response )
      update_service_response_for( local_service_response, interface )

      upc  = []
      upc << ident unless ident.nil? || ident.empty?

      action = determine_action(
        interface,
        http_method,
        upc.empty?,
        local_service_response
      )

      if local_service_response.halt_processing?
        @service_response.errors.merge!( local_service_response.errors )
        return nil
      end

      local_service_request                     = new_service_request_for( interface )
      local_service_request.uri_path_components = upc
      local_service_request.uri_path_extension  = ''

      unless query_hash.nil?
        query_hash = ApiTools::Utilities.stringify( query_hash )

        # This is for inter-service local calls where a service author
        # specifies ":_embed => 'foo'" accidentally, forgetting that it
        # should be a single element array. It's such a common mistake
        # that we tolerate it here. Same for "_reference".

        data = query_hash[ '_embed' ]
        query_hash[ '_embed' ] = [ data ] if data.is_a?( ::String ) || data.is_a?( ::Symbol )

        data = query_hash[ '_reference' ]
        query_hash[ '_reference' ] = [ data ] if data.is_a?( ::String ) || data.is_a?( ::Symbol )

        # Regardless, make sure embed/reference array data contains strings.

        query_hash[ '_embed'     ].map!( &:to_s ) unless query_hash[ '_embed'     ].nil?
        query_hash[ '_reference' ].map!( &:to_s ) unless query_hash[ '_reference' ].nil?

        process_query_hash(
          action,
          query_hash,
          interface,
          local_service_request,
          local_service_response
        )
      end

      if local_service_response.halt_processing?
        @service_response.errors.merge!( local_service_response.errors )
        return nil
      end

      local_service_request.body = body_hash

      # Dispatch the call, merge any errors that might have come back and
      # return the body of the called service's response.

      debug_log( "Dispatching local inter-service call with parsed body data: '#{ local_service_request.body }'" )

      context = ApiTools::ServiceContext.new(
        @service_session,
        local_service_request,
        local_service_response,
        self
      )

      dispatch_to( interface, implementation, action, context )

      @service_response.errors.merge!( local_service_response.errors )

      return local_service_response.body
    end

    # See also:
    #
    #   rack_monkey_patch.rb
    #   service_endpoint.rb
    #   service_registry_drb_server.rb
    #   service_registry_drb_configuration.rb

    # The following must appear at the end of this class definition.

    # For local development, a DRb service is used. We thus must
    # "disable eval() and friends":
    #
    # http://www.ruby-doc.org/stdlib-1.9.3/libdoc/drb/rdoc/DRb.html
    #
    $SAFE = 1

    # Singleton "Front object" for the DRB service used in local development.
    #
    FRONT_OBJECT = ApiTools::ServiceMiddleware::ServiceRegistryDRbServer.new

  end   # 'class ServiceMiddleware'
end     # 'module ApiTools'
