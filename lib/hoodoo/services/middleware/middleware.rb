########################################################################
# File::    middleware.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Rack middleware, declared in a +config.ru+ file in the usual
#           way - "use( Hoodoo::Services::Middleware )".
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
#           16-Oct-2014 (TC):  Added Session Code.
#           11-Nov-2014 (ADH): Some internal classes split out into
#                              their own files to reduce file size here.
########################################################################

require 'set'
require 'cgi'
require 'uri'
require 'json'
require 'benchmark'

require 'hoodoo/services/services/permissions'
require 'hoodoo/services/services/session'
require 'hoodoo/discovery'
require 'hoodoo/client'

module Hoodoo; module Services

  # Rack middleware, declared in (e.g.) a +config.ru+ file in the usual way:
  #
  #      use( Hoodoo::Services::Middleware )
  #
  # This is the core of the common service implementation on the Rack
  # client-request-handling side. It is run in the context of an
  # Hoodoo::Services::Service subclass that's been given to Rack as the Rack
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
  # The middleware supports structured logging through Hoodoo::Logger via the
  # custom Hoodoo::Services::Middleware::AMQPLogWriter class. Access the logger
  # instance with Hoodoo::Services::Middleware::logger. Call +report+ on this
  # (see Hoodoo::Logger::WriterMixin#report) to make structured log entries.
  # The middleware's own entries use component +Middleware+ for general data.
  # It also logs essential essential information about successful and failed
  # interactions with resource endpoints using the resource name as the
  # component. In such cases, the codes it uses are always prefixed by
  # +middleware_+ and service applications must consider codes with this prefix
  # reserved - do not use such codes yourself.
  #
  # The middleware adds a STDERR stream writer logger by default and an AMQP
  # log writer on the first Rack +call+ should the Rack environment provide an
  # Alchemy endpoint (see the Alchemy Flux gem).
  #
  class Middleware

    # The "category" directive below is required to work around an RDoc
    # bug where Middleware is viewed as a namespace rather than a class in
    # its own right, with documentation of constants otherwise entirely
    # omitted. By putting one constant in its own category, RDoc ends up
    # making them all visible.

    # :category: Public constants
    #
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

    # All allowed HTTP methods, related to ALLOWED_ACTIONS.
    #
    ALLOWED_HTTP_METHODS = Set.new( %w( GET POST PATCH DELETE ) )

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

    # Prohibited fields in creations or updates - these are the common fields
    # specified in the API, which are emergent in the platform or are set via
    # other routes (e.g. "language" comes from HTTP headers in requests). This
    # is obtained via the Hoodoo::Presenters::CommonResourceFields class and
    # its described field schema, so see that for details.
    #
    PROHIBITED_INBOUND_FIELDS = Hoodoo::Presenters::CommonResourceFields.get_schema().properties.keys

    # Somewhat arbitrary maximum incoming payload size to prevent ham-fisted
    # DOS attempts to consume RAM.
    #
    MAXIMUM_PAYLOAD_SIZE = 1048576 # 1MB Should Be Enough For Anyone

    # Maximum *logged* payload (inbound data) size.
    # Keep consistent with max payload size so data is not lost from the logs.
    #
    MAXIMUM_LOGGED_PAYLOAD_SIZE = MAXIMUM_PAYLOAD_SIZE

    # Maximum *logged* response (outbound data) size.
    # Keep consistent with max payload size so data is not lost from the logs.
    #
    MAXIMUM_LOGGED_RESPONSE_SIZE = MAXIMUM_PAYLOAD_SIZE

    # The default test session; a Hoodoo::Services::Session instance with the
    # following characteristics:
    #
    # Session ID::      +01234567890123456789012345678901+
    # Caller ID::       +c5ea12fb7f414a46850e73ee1bf6d95e+
    # Caller Version::  1
    # Permissions::     Default/else/"allow" to allow all actions
    # Identity::        Has +caller_id+ as its only field
    # Scoping::         All secured HTTP headers are allowed
    # Expires at:       Now plus 2 days
    #
    # See also ::test_session and ::set_test_session.
    #
    DEFAULT_TEST_SESSION = Hoodoo::Services::Session.new

    # This is NOT a canonical way to construct a session! Both the Permissions
    # object and Session object should be put together using defined methods,
    # not by assuming hash layout. This is done *purely internally* within the
    # middleware for simplicity/speed at parse time.
    #
    DEFAULT_TEST_SESSION.from_h!( {
      'session_id'           => '01234567890123456789012345678901',
      'expires_at'           => Hoodoo::Utilities.standard_datetime( Time.now + 172800 ),
      'caller_version'       => 1,
      'caller_id'            =>                  'c5ea12fb7f414a46850e73ee1bf6d95e',
      'caller_identity_name' =>                  'c5ea12fb7f414a46850e73ee1bf6d95e',
      'caller_fingerprint'   =>                  '7bc0b402a77543a49d0b1b671253fb25',
      'identity'             => { 'caller_id' => 'c5ea12fb7f414a46850e73ee1bf6d95e' },
      'permissions'          => Hoodoo::Services::Permissions.new( {
        'default' => { 'else' => Hoodoo::Services::Permissions::ALLOW }
      } ).to_h,
      'scoping' => {
        'authorised_http_headers' => Hoodoo::Client::Headers::HEADER_TO_PROPERTY.map() { | key, sub_hash |
          sub_hash[ :header ] if sub_hash[ :secured ] == true
        }.compact
      }
    } )

    # A validation Proc for FRAMEWORK_QUERY_DATA - see that for details. This
    # one ensures that the value is a valid ISO 8601 subset date/time string
    # and evaluates to the parsed version of that string if so.
    #
    FRAMEWORK_QUERY_VALUE_DATE_PROC = -> ( value ) {
      Hoodoo::Utilities.valid_iso8601_subset_datetime?( value ) ?
      Hoodoo::Utilities.rationalise_datetime( value )           :
      nil
    }

    # A validation Proc for FRAMEWORK_QUERY_DATA - see that for details. This
    # one ensures that the value is a valid UUID and evaluates to that UUID
    # string if so.
    #
    FRAMEWORK_QUERY_VALUE_UUID_PROC = -> ( value ) {
      value = Hoodoo::UUID.valid?( value ) && value
      value || nil # => 'value' if 'value' is truthy, 'nil' if 'value' falsy
    }

    # Out-of-box search and filter query keys. Interfaces can override the
    # support for these inside the Hoodoo::Services::Interface.to_list block
    # using Hoodoo::Services::Interface::ToListDSL.do_not_search and
    # Hoodoo::Services::Interface::ToListDSL.do_not_filter.
    #
    # Keys, in order, are:
    #
    # * Query key to detect records with a +created_at+ date that is after the
    #   given value, in supporting resource; if used as a filter instead of a
    #   search string, would find records on-or-before the date.
    #
    # * Query key to detect records with a +created_at+ date that is before
    #   the given value, in supporting resource; if used as a filter instead
    #   of a search string, would find records on-or-after the date.
    #
    # Values are either a validation Proc or +nil+ for no validation. The
    # Proc takes the search query value as its sole input parameter and must
    # evaluate to the input value either unmodified or in some canonicalised
    # form if it is valid, else to +nil+ if the input value is invalid. The
    # canonicalisation is typically used to coerce a URI query string based
    # String type into a more useful comparable entity such as an Integer or
    # DateTime.
    #
    # *IMPORTANT* - if this list is changed, any database support modules -
    # e.g. in Hoodoo::ActiveRecord::Support - will need any internal mapping
    # of "framework query keys to module-appropriate query code" updating.
    #
    FRAMEWORK_QUERY_DATA = {
      'created_after'  => FRAMEWORK_QUERY_VALUE_DATE_PROC,
      'created_before' => FRAMEWORK_QUERY_VALUE_DATE_PROC,
      'created_by'     => FRAMEWORK_QUERY_VALUE_UUID_PROC
    }

    # Utility - returns the execution environment as a Rails-like environment
    # object which answers queries like +production?+ or +staging?+ with +true+
    # or +false+ according to the +RACK_ENV+ environment variable setting.
    #
    # Example:
    #
    #     if Hoodoo::Services::Middleware.environment.production?
    #       # ...do something only if RACK_ENV="production"
    #     end
    #
    def self.environment
      @@environment ||= Hoodoo::StringInquirer.new( ENV[ 'RACK_ENV' ] || 'development' )
    end

    # This method is deprecated. Use ::has_session_store? instead.
    #
    # Return a boolean value for whether Memcached is explicitly defined as
    # the Hoodoo::TransientStore engine. In previous versions, a +nil+ response
    # used to indicate local development without a queue available, but that is
    # not a valid assumption in modern code.
    #
    def self.has_memcached?
      m = self.memcached_host()
      m.nil? == false && m.empty? == false
    end

    # Return a boolean value for whether an environment variable declaring
    # Hoodoo::TransientStore engine URI(s) have been defined by service author.
    #
    def self.has_session_store?
      config = self.session_store_uri()
      config.nil? == false && config.empty? == false
    end

    # This method is deprecated. Use ::session_store_uri instead.
    #
    # Return a Memcached host (IP address/port combination) as a String if
    # defined in environment variable MEMCACHED_HOST (with MEMCACHE_URL also
    # accepted as a legacy fallback).
    #
    # If this returns +nil+ or an empty string, there's no defined Memcached
    # host available.
    #
    def self.memcached_host

      # See also ::clear_memcached_configuration_cache!.
      #
      @@memcached_host ||= ENV[ 'MEMCACHED_HOST' ] || ENV[ 'MEMCACHE_URL' ]

    end

    # This method is intended really just for testing purposes; it clears the
    # internal cache of Memcached data read from environment variables.
    #
    def self.clear_memcached_configuration_cache!
      @@memcached_host = nil
    end

    # Return configuration for the selected Hoodoo::TransientStore engine, as
    # a flat String (IP address/ port combination) or a serialised JSON string
    # with symbolised keys, defining a URI for each supported storage engine
    # defined (required if <tt>ENV[ 'SESSION_STORE_ENGINE' ]</yy> defines a
    # multi-engine strategy).
    #
    # Checks for the engine agnostic environment variable +SESSION_STORE_URI+
    # first then uses #memcached_host as a legacy fallback.
    #
    def self.session_store_uri

      # See also ::clear_session_store_configuration_cache!
      #
      @@session_store_uri ||= ( ENV[ 'SESSION_STORE_URI' ] || self.memcached_host() )

    end

    # Return a symbolised key for the transient storage engine as defined in
    # the environment variable +SESSION_STORE_ENGINE+ (with +:memcached+ as a
    # legacy fallback if ::has_memcached? is +true+, else default is +nil+).
    #
    # The +SESSION_STORE_ENGINE+ environment variable must contain an entry
    # from Hoodoo::TransientStore::supported_storage_engines. This collection
    # is initialised by either requiring the top-level +hoodoo+ file to pull
    # in everything, requiring <tt>hoodoo/transient_store</tt> to pull in all
    # currently defined transient store engines or requiring the following
    # in order to pull in a specific engine - in this example, redis:
    #
    #         require 'hoodoo/transient_store/transient_store'
    #         require 'hoodoo/transient_store/transient_store/base'
    #         require 'hoodoo/transient_store/transient_store/redis'
    #
    # If the engine requested appears to be unsupported, this method returns
    # +nil+.
    #
    def self.session_store_engine
      if (
        ! defined?( @@session_store_engine ) ||
        @@session_store_engine.nil?          ||
        @@session_store_engine.empty?
      )
        default = self.has_memcached? ? 'memcached' : ''
        engine = ( ENV[ 'SESSION_STORE_ENGINE' ] || default ).to_sym()

        if Hoodoo::TransientStore::supported_storage_engines.include?( engine )
          @@session_store_engine = engine
        else
          @@session_store_engine = nil
        end
      end

      @@session_store_engine
    end

    # This method is intended really just for testing purposes; it clears the
    # internal cache of session storage engine data read from environment
    # variables.
    #
    def self.clear_session_store_configuration_cache!
      @@session_store_engine = nil
      @@session_store_uri    = nil
    end

    # Are we running on the queue, else (implied) a local HTTP server?
    #
    def self.on_queue?

      # See also ::clear_queue_configuration_cache!.
      #
      @@amq_uri ||= ENV[ 'AMQ_URI' ]
      @@amq_uri.nil? == false && @@amq_uri.empty? == false

    end

    # This method is intended really just for testing purposes; it clears the
    # internal cache of AMQP queue data read from environment variables.
    #
    def self.clear_queue_configuration_cache!
      @@amq_uri = nil
    end

    # Return a service 'name' derived from the service's collection of
    # declared resources. The name will be the same across any instances of
    # the service that implement the same resources. This can be used for
    # e.g. AMQP-based queue-named operations, that want to target the same
    # resource collection regardless of instance.
    #
    # This method will not work unless the middleware has parsed the set
    # of service interface declarations (during instance initialisation).
    # If a least one middleware instance has already been created, it is
    # safe to call.
    #
    def self.service_name
      @@service_name
    end

    # For a given resource name and version, return the _de_ _facto_ routing
    # path based on version and name with no modifications.
    #
    # +resource+::    Resource name for the endpoint, e.g. +:Purchase+.
    #                 String or symbol.
    #
    # +version+::     Implemented version of the endpoint. Integer.
    #
    def self.de_facto_path_for( resource, version )
      "/#{ version }/#{ resource }"
    end

    # Access the middleware's logging instance. Call +report+ on this to make
    # structured log entries. See Hoodoo::Logger::WriterMixin#report along
    # with Hoodoo::Logger for other calls you can use.
    #
    # The logging system 'wakes up' in stages. Initially, only console based
    # output is added, as the Middleware Ruby code is parsed and configures
    # a basic logger. If you call ::set_log_folder, file-based logging may be
    # available. In AMQP based environments, queue based logging will become
    # automatically available via Rack and the Alchemy gem once the middleware
    # starts handling its very first request, but not before.
    #
    # With this in mind, the logger is ultimately configured with a set of
    # writers as follows:
    #
    # * If off queue:
    #   * All RACK_ENV values (including "test"):
    #     * File "log/{environment}.log"
    #   * RACK_ENV "development"
    #     * Also to $stdout
    #
    # * If on queue:
    #   * RACK ENV "test"
    #     * File "log/test.log"
    #   * All other RACK_ENV values
    #     * AMQP writer (see below)
    #   * RACK_ENV "development"
    #     * Also to $stdout
    #
    # Or to put it another way, in test mode only file output to 'test.log'
    # happens; in development mode $stdout always happens; and in addition
    # for non-test environment, you'll get a queue-based or file-based
    # logger depending on whether or not a queue is available.
    #
    # See Hoodoo::Services::Interface#secure_logs_for for information about
    # security considerations when using logs.
    #
    def self.logger
      @@logger # See self.set_up_basic_logging and self.set_logger
    end

    # The middleware sets up a logger itself (see ::logger) with various log
    # mechanisms set up (mostly) without service author intervention.
    #
    # If you want to completely override the middleware's logger and replace
    # it with your own at any time (not recommended), call here.
    #
    # See Hoodoo::Services::Interface#secure_logs_for for information about
    # security considerations when using logs.
    #
    # +logger+:: Alternative Hoodoo::Logger instance to use for all
    #            middleware logging from this point onwards. The value will
    #            subsequently be returned by the ::logger class method.
    #
    def self.set_logger( logger )
      unless logger.is_a?( Hoodoo::Logger )
        raise "Hoodoo::Communicators::set_logger must be called with an instance of Hoodoo::Logger only"
      end

      @@external_logger = true
      @@logger          = logger
    end

    # If using the middleware logger (see ::logger) with no external custom
    # logger set up (see ::set_logger), call here to configure the folder
    # used for logs when file output is active.
    #
    # If you don't do this at least once, no log file output can occur.
    #
    # You can call more than once to output to more than one log folder.
    #
    # See Hoodoo::Services::Interface#secure_logs_for for information about
    # security considerations when using logs.
    #
    # +base_path+:: Path to folder to use for logs; file "#{environment}.log"
    #               may be written inside (see ::environment).
    #
    def self.set_log_folder( base_path )
      self.send( :add_file_logging, base_path )
    end

    # Set verbose logging. With verbose logging enabled, additional payload
    # data is added - most notably, full session details (where possible)
    # are included in each log message. These can increase log data size
    # considerably, but may be useful if you encounter session-related
    # errors or general operational issues and need log data to provide more
    # insights.
    #
    # Verbose logging is _disabled_ by default.
    #
    # +verbose+:: +true+ to enable verbose logging, +false+ to disable it.
    #             The default is +false+.
    #
    def self.set_verbose_logging( verbose )
      @@verbose_logging = verbose
    end

    # Returns +true+ if verbose logging is enabled, else +false+. For more,
    # see ::set_verbose_logging.
    #
    def self.verbose_logging?
      defined?( @@verbose_logging ) ? @@verbose_logging : false
    end

    # A Hoodoo::Services::Session instance to use for tests or when no
    # local Hoodoo::TransientStore instance is known about (environment
    # variable +SESSION_STORE_ENGINE+ and +SESSION_STORE_URI+ are not set).
    # The session is (eventually) read each time a request is made via
    # Rack (through #call).
    #
    # "Out of the box", DEFAULT_TEST_SESSION is used.
    #
    def self.test_session
      @@test_session
    end

    # Set the test session instance. See ::test_session for details.
    #
    # +session+:: A Hoodoo::Services::Session instance to use as the test
    #             session instance for any subsequently-made requests. If
    #             +nil+, the test session system acts as if an invalid or
    #             missing session ID had been supplied.
    #
    def self.set_test_session( session )
      @@test_session = session
    end

    self.set_test_session( DEFAULT_TEST_SESSION )

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

    # For test purposes, dump the internal service records and flush the DRb
    # service, if it is running. Existing middleware
    # instances will be invalidated. New instances must be created to re-scan
    # their services internally and (where required) inform the DRb process
    # of the endpoints.
    #
    def self.flush_services_for_test
      @@services     = []
      @@service_name = nil

      ObjectSpace.each_object( self ) do | middleware_instance |
        discoverer = middleware_instance.instance_variable_get( '@discoverer' )
        discoverer.flush_services_for_test() if discoverer.respond_to?( :flush_services_for_test )
      end
    end

    # Initialize the middleware instance.
    #
    # +app+ Rack app instance to which calls should be passed.
    #
    def initialize( app )

      service_container = app

      if defined?( NewRelic ) &&
         defined?( NewRelic::Agent ) &&
         defined?( NewRelic::Agent::Instrumentation ) &&
         defined?( NewRelic::Agent::Instrumentation::MiddlewareProxy ) &&
         service_container.is_a?( NewRelic::Agent::Instrumentation::MiddlewareProxy )

        if service_container.respond_to?( :target )
          service_container = service_container.target()
        else
          raise "Hoodoo::Services::Middleware instance created with NewRelic-wrapped Service entity, but NewRelic API is not as expected by Hoodoo; incompatible NewRelic version."
        end
      end

      unless service_container.is_a?( Hoodoo::Services::Service )
        raise "Hoodoo::Services::Middleware instance created with non-Service entity of class '#{ service_container.class }' - is this the last middleware in the chain via 'use()' and is Rack 'run()'-ing the correct thing?"
      end

      # Collect together the implementation instances and the matching regexps
      # for endpoints. An array of hashes.
      #
      # Key              Value
      # =======================================================================
      # regexp           Regexp for +String#match+ on the URI path component
      # interface        Hoodoo::Services::Interface subclass associated with
      #                  the endpoint regular expression in +regexp+
      # actions          Set of symbols naming allowed actions
      # implementation   Hoodoo::Services::Implementation subclass *instance* to
      #                  use on match
      #
      @@services = service_container.component_interfaces.map do | interface |

        if interface.nil? || interface.endpoint.nil? || interface.implementation.nil?
          raise "Hoodoo::Services::Middleware encountered invalid interface class #{ interface } via service class #{ service_container.class }"
        end

        # If anything uses a public interface, we need to tell ourselves that
        # the early exit session check can't be done.
        #
        interfaces_have_public_methods() unless interface.public_actions.empty?

        # There are two routes to an implementation - one via the custom path
        # given through its 'endpoint' declaration, the other a de facto path
        # determined from the unmodified version and resource name. Both lead
        # to the same implementation instance.
        #
        implementation_instance = interface.implementation.new

        # Regexp explanation:
        #
        # Match "/", the version text, "/", the endpoint text, then either
        # another "/", a "." or the end of the string, followed by capturing
        # everything else. Match data index 1 will be whatever character (if
        # any) followed after the endpoint ("/" or ".") while index 2 contains
        # everything else.
        #
        custom_path   = "/v#{ interface.version }/#{ interface.endpoint }"
        custom_regexp = /^\/v#{ interface.version }\/#{ interface.endpoint }(\.|\/|$)(.*)/

        # Same as above, but for the de facto routing.
        #
        de_facto_path   = self.class.de_facto_path_for( interface.resource, interface.version )
        de_facto_regexp = /^\/#{ interface.version }\/#{ interface.resource }(\.|\/|$)(.*)/

        Hoodoo::Services::Discovery::ForLocal.new(
          :resource                => interface.resource,
          :version                 => interface.version,
          :base_path               => custom_path,
          :routing_regexp          => custom_regexp,
          :de_facto_base_path      => de_facto_path,
          :de_facto_routing_regexp => de_facto_regexp,
          :interface_class         => interface,
          :implementation_instance => implementation_instance
        )

      end

      # Determine the service name from the resources above then announce
      # the whole collection to any interested discovery engines.

      sorted_resources = @@services.map() { | service | service.resource }.sort()
      @@service_name   = "service.#{ sorted_resources.join( '_' ) }"

      announce_presence_of( @@services )
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

        enable_alchemy_logging_from( env )

        interaction = Hoodoo::Services::Middleware::Interaction.new( env, self )
        debug_log( interaction )

        early_response = preprocess( interaction )
        return early_response unless early_response.nil?

        response = interaction.context.response

        process( interaction )     unless response.halt_processing?
        postprocess( interaction ) unless response.halt_processing?

        return respond_for( interaction )

      rescue => exception
        begin
          if interaction && interaction.context
            ExceptionReporting.contextual_report( exception, interaction.context )
          else
            ExceptionReporting.report( exception, env )
          end

          record_exception( interaction, exception )

          return respond_for( interaction )

        rescue => inner_exception
          begin
            backtrace       = ''
            inner_backtrace = ''

            if self.class.environment.test? || self.class.environment.development?
              backtrace       = exception.backtrace
              inner_backtrace = inner_exception.backtrace
            else
              ''
            end

            @@logger.error(
              'Hoodoo::Services::Middleware#call',
              'Middleware exception in exception handler',
              inner_exception.to_s,
              inner_backtrace.to_s,
              '...while handling...',
              exception.to_s,
              backtrace.to_s
            )
          rescue
            # Ignore logger exceptions. Can't do anything about them. Just
            # try and get the response back to the client now.
          end

          # An exception in the exception handler! Oh dear.
          #
          rack_response = Rack::Response.new
          rack_response.status = 500
          rack_response.write( 'Middleware exception in exception handler' )
          return rack_response.finish

        end
      end
    end

    # Return something that behaves like a Hoodoo::Client::Endpoint subclass
    # instance which can be used for inter-resource communication, whether
    # the target endpoint implementation is local or remote.
    #
    # +resource+::    Resource name for the endpoint, e.g. +:Purchase+.
    #                 String or symbol.
    #
    # +version+::     Required implemented version for the endpoint. Integer.
    #
    # +interaction+:: The Hoodoo::Services::Middleware::Interaction instance
    #                 describing the inbound call, the processing of which is
    #                 leading to a request for an inter-resource call by an
    #                 endpoint implementation.
    #
    def inter_resource_endpoint_for( resource, version, interaction )
      resource = resource.to_sym
      version  = version.to_i

      # Build a Hash of any options which should be transferred from one
      # endpoint to another for inter-resource calls, along with other
      # options common to local and remote endpoints.

      endpoint_options = {
        :interaction => interaction,
        :locale      => interaction.context.request.locale,
      }

      Hoodoo::Client::Headers::HEADER_TO_PROPERTY.each do | rack_header, description |
        property = description[ :property ]

        if description[ :auto_transfer ] == true
          endpoint_options[ property ] = interaction.context.request.send( property )
        end
      end

      if @discoverer.is_local?( resource, version )

        # For local inter-resource calls, return the middleware's endpoint
        # for that. In turn, if used this calls into #inter_resource_local.

        discovery_result = @@services.find do | entry |
          interface = entry.interface_class
          interface.resource == resource && interface.version == version
        end

        if discovery_result.nil?
          raise "Hoodoo::Services::Middleware\#inter_resource_endpoint_for: Internal error - version #{ version } of resource #{ resource } endpoint is local according to the discovery engine, but no local service discovery record can be found"
        end

        endpoint_options[ :discovery_result ] = discovery_result

        return Hoodoo::Services::Middleware::InterResourceLocal.new(
          resource,
          version,
          endpoint_options
        )

      else

        # For remote inter-resource calls, use Hoodoo::Client's endpoint
        # factory to get a (say) HTTP or AMQP contact endpoint, but then
        # wrap it with the middleware's remote call endpoint, since the
        # request requires extra processing before it goes to the Client
        # (e.g. session permission augmentation) and the result needs
        # extra processing before it is returned to the caller (e.g.
        # delete an augmented session, annotate any errors from call).

        endpoint_options[ :discoverer ] = @discoverer
        endpoint_options[ :session    ] = interaction.context.session

        wrapped_endpoint = Hoodoo::Client::Endpoint.endpoint_for(
          resource,
          version,
          endpoint_options
        )

        if wrapped_endpoint.is_a?( Hoodoo::Client::Endpoint::AMQP ) && defined?( @@alchemy )
          wrapped_endpoint.alchemy = @@alchemy
        end

        # Using "ForRemote" here is redundant - we could just as well
        # pass wrapped_endpoint directly to an option in the
        # InterResourceRemote class - but keeping "with the pattern"
        # just sort of 'seems right' and might be useful in future.

        discovery_result = Hoodoo::Services::Discovery::ForRemote.new(
          :resource         => resource,
          :version          => version,
          :wrapped_endpoint => wrapped_endpoint
        )

        return Hoodoo::Services::Middleware::InterResourceRemote.new(
          resource,
          version,
          {
            :interaction      => interaction,
            :discovery_result => discovery_result
          }
        )
      end
    end

    # Make a local (non-HTTP local Ruby method call) inter-resource call. This
    # is fast compared to any remote resource call, even though there is still
    # a lot of overhead involved in setting up data so that the target
    # resource "sees" the call in the same way as any other.
    #
    # Named parameters are as follows:
    #
    # +source_interaction+:: A Hoodoo::Services::Middleware::Interaction
    #                        instance for the inbound call which is being
    #                        processed right now by some resource endpoint
    #                        implementation and this implementation is now
    #                        making an inter-resource call as part of its
    #                        processing;
    #
    # +discovery_result+::   A Hoodoo::Services::Discovery::ForLocal instance
    #                        describing the target of the inter-resource call;
    #
    # +endpoint+::           The calling Hoodoo::Client::Endpoint subclass
    #                        instance (used for e.g. locale, dated-at);
    #
    # +action+::             A Hoodoo::Services::Middleware::ALLOWED_ACTIONS
    #                        entry;
    #
    # +ident+::              UUID or other unique identifier of a resource
    #                        instance. Required for +show+, +update+ and
    #                        +delete+ actions, ignored for others;
    #
    # +query_hash+::         Optional Hash of query data to be turned into a
    #                        query string - applicable to any action;
    #
    # +body_hash+::          Hash of data to convert to a body string using
    #                        the source interaction's described content type.
    #                        Required for +create+ and +update+ actions,
    #                        ignored for others.
    #
    # A Hoodoo::Client::AugmentedArray or Hoodoo::Client::AugmentedHash is
    # returned from these methods; @response or the wider processing context
    # is not automatically modified. Callers MUST use the methods provided by
    # Hoodoo::Client::AugmentedBase to detect and handle error conditions,
    # unless for some reason they wish to ignore inter-resource call errors.
    #
    def inter_resource_local( source_interaction:,
                              discovery_result:,
                              endpoint:,
                              action:,
                              ident:      nil,
                              body_hash:  nil,
                              query_hash: nil )

      # We must construct a call context for the local service. This means
      # a local request object which we fill in with data just as if we'd
      # parsed an inbound HTTP request and a response object that contains
      # the usual default data.

      interface      = discovery_result.interface_class
      implementation = discovery_result.implementation_instance

      # Need to possibly augment the caller's session - same rationale
      # as #local_service_remote, so see that for details.

      session = source_interaction.context.session

      unless session.nil? || source_interaction.using_test_session?
        session = session.augment_with_permissions_for( source_interaction )
      end

      if session == false
        hash = Hoodoo::Client::AugmentedHash.new
        hash.platform_errors.add_error( 'platform.invalid_session' )
        return hash
      end

      mock_rack_env = {
        'HTTP_X_INTERACTION_ID' => source_interaction.interaction_id
      }

      local_interaction = Hoodoo::Services::Middleware::Interaction.new(
        mock_rack_env,
        self,
        session
      )

      local_interaction.target_interface           = interface
      local_interaction.target_implementation      = implementation
      local_interaction.requested_content_type     = source_interaction.requested_content_type
      local_interaction.requested_content_encoding = source_interaction.requested_content_encoding

      # For convenience...

      local_request  = local_interaction.context.request
      local_response = local_interaction.context.response

      # Carry through any endpoint-specified request orientated attributes.

      local_request.locale = endpoint.locale

      Hoodoo::Client::Headers::HEADER_TO_PROPERTY.each do | rack_header, description |
        property        = description[ :property        ]
        property_writer = description[ :property_writer ]

        value = endpoint.send( property )

        local_request.send( property_writer, value ) unless value.nil?
      end

      # Initialise the response data.

      set_common_response_headers( local_interaction )
      update_response_for( local_response, interface )

      # Work out what kind of result the caller is expecting.

      result_class = if action == :list
        Hoodoo::Client::AugmentedArray
      else
        Hoodoo::Client::AugmentedHash
      end

      # Add errors from the local service response into an augmented object
      # for responding early (via a Proc for internal reuse later).

      add_local_errors = Proc.new {
        result                  = result_class.new
        result.response_options = Hoodoo::Client::Headers.x_header_to_options(
          local_response.headers
        )

        result.platform_errors.merge!( local_response.errors )
        result
      }

      # Figure out initial action / authorisation results for this request.
      # We may still have to construct a context and ask the service after.

      upc  = []
      upc << ident unless ident.nil? || ident.empty?

      local_interaction.requested_action = action
      authorisation                      = determine_authorisation( local_interaction )

      # In addition, check security on any would-have-been-a-secured-header
      # property.

      return add_local_errors.call() if local_response.halt_processing?

      Hoodoo::Client::Headers::HEADER_TO_PROPERTY.each do | rack_header, description |

        next if description[ :secured ] != true
        next if endpoint.send( description[ :property ] ).nil?

        real_header = description[ :header ]

        if (
             session.respond_to?( :scoping ) == false ||
             session.scoping.respond_to?( :authorised_http_headers ) == false ||
             session.scoping.authorised_http_headers.respond_to?( :include? ) == false ||
             (
               session.scoping.authorised_http_headers.include?( rack_header ) == false &&
               session.scoping.authorised_http_headers.include?( real_header ) == false
             )
           )

          local_response.errors.add_error( 'platform.forbidden' )
          break
        end
      end

      return add_local_errors.call() if local_response.halt_processing?

      deal_with_x_assume_identity_of( local_interaction )

      return add_local_errors.call() if local_response.halt_processing?

      # Construct the local request details.

      local_request.uri_path_components = upc
      local_request.uri_path_extension  = ''

      unless query_hash.nil?
        query_hash = Hoodoo::Utilities.stringify( query_hash )

        # This is for inter-resource local calls where a service author
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

        process_query_hash( local_interaction, query_hash )
      end

      local_request.body = body_hash

      # The inter-resource local backend does not accept or process the
      # equivalent of the X-Resource-UUID "set the ID to <this>" HTTP
      # header, so we do not call "maybe_update_body_data_for()" here;
      # we only need to validate it.
      #
      if ( action == :create || action == :update )
        validate_body_data_for( local_interaction )
      end

      return add_local_errors.call() if local_response.halt_processing?

      # Can now, if necessary, do a final check with the target endpoint
      # for authorisation.

      if authorisation == Hoodoo::Services::Permissions::ASK
        ask_for_authorisation( local_interaction )
        return add_local_errors.call() if local_response.halt_processing?
      end

      # Dispatch the call.

      debug_log( local_interaction, 'Dispatching local inter-resource call', local_request.body )
      dispatch( local_interaction )

      # If we get this far the interim session isn't needed. We might have
      # exited early due to errors above and left this behind, but that's not
      # the end of the world - it'll expire out of the Hoodoo::TransientStore
      # eventually.
      #
      if session &&
         source_interaction.context &&
         source_interaction.context.session &&
         session.session_id != source_interaction.context.session.session_id

        # Ignore errors, there's nothing much we can do about them and in
        # the worst case we just have to wait for this to expire naturally.

        session.delete_from_store()
      end

      # Extract the returned data, handling error conditions.

      if local_response.halt_processing?
        result = result_class.new
        result.set_platform_errors(
          annotate_errors_from_other_resource( local_response.errors )
        )

      else
        body = local_response.body

        if action == :list && body.is_a?( ::Array )
          result                        = Hoodoo::Client::AugmentedArray.new( body )
          result.dataset_size           = local_response.dataset_size
          result.estimated_dataset_size = local_response.estimated_dataset_size

        elsif action != :list && body.is_a?( ::Hash )
          result = Hoodoo::Client::AugmentedHash[ body ]

        elsif local_request.deja_vu && body == ''
          result = result_class.new

        else
          raise "Hoodoo::Services::Middleware: Unexpected response type '#{ body.class.name }' received from a local inter-resource call for action '#{ action }'"

        end

      end

      result.response_options = Hoodoo::Client::Headers.x_header_to_options(
        local_response.headers
      )

      return result
    end

    # Make an "inbound" call log based on the given interaction.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction describing the
    #                 inbound request. The +interaction_id+, +rack_request+ and
    #                 +session+ data is used (the latter being optional). If
    #                 +target_interface+ and +requested_action+ are available,
    #                 body data _might_ be logged according to secure log
    #                 settings in the interface; if these values are unset,
    #                 body data is _not_ logged.
    #
    def monkey_log_inbound_request( interaction )

      data = build_common_log_data_for( interaction )

      # Annoying dance required to extract all HTTP header data from Rack.

      env     = interaction.rack_request.env
      headers = env.select do | key, value |
        key.to_s.match( /^HTTP_/ )
      end

      headers[ 'CONTENT_TYPE'   ] = env[ 'CONTENT_TYPE'   ]
      headers[ 'CONTENT_LENGTH' ] = env[ 'CONTENT_LENGTH' ]

      data[ :payload ] = {
        :method  => env[ 'REQUEST_METHOD', ],
        :scheme  => env[ 'rack.url_scheme' ],
        :host    => env[ 'SERVER_NAME'     ],
        :port    => env[ 'SERVER_PORT'     ],
        :script  => env[ 'SCRIPT_NAME'     ],
        :path    => env[ 'PATH_INFO'       ],
        :query   => env[ 'QUERY_STRING'    ],
        :headers => headers
      }

      # Deal with body data and security issues.

      secure    = true
      interface = interaction.target_interface
      action    = interaction.requested_action

      unless interface.nil? || action.nil?
        secure_log_actions = interface.secure_log_for()
        secure_type        = secure_log_actions[ action ]

        # Allow body logging if there's no security specified for this action
        # or the security is specified for the response only (since we log the
        # request here).
        #
        # This means values of :both or :request will leave "secure" unchanged,
        # as will any other unexpected value that might get specified.

        secure = false if secure_type.nil? || secure_type == :response
      end

      # Compile the remaining log payload and send it.

      unless secure
        body = nil
        if !interaction.rack_request.body.nil?
          body = interaction.rack_request.body.read( MAXIMUM_LOGGED_PAYLOAD_SIZE )
                 interaction.rack_request.body.rewind()
        end

        data[ :payload ][ :body ] = body
      end

      @@logger.report(
        :info,
        :Middleware,
        :inbound,
        data
      )

      return nil
    end

  private

    @@interfaces_have_public_methods = false

    # Note internally that at least one interface in this Ruby process has
    # a public interface. This means that the normal early exit for invalid
    # or missing session keys cannot be performed; we have to continue down
    # the processing chain as far as determining the target interface and
    # action in order to find out if it's public or not and *then* check
    # the session, if necessary. This is clearly less efficient and maybe a
    # bit more risky.
    #
    def interfaces_have_public_methods
      @@interfaces_have_public_methods = true
    end

    # Do any interfaces in this Ruby process have public methods, requiring
    # no session data? If so returns +true+, else +false+.
    #
    def interfaces_have_public_methods?
      @@interfaces_have_public_methods
    end

    # Private class method.
    #
    # Sets up a logger instance with appropriate log level for the environment
    # (see ::environment) and any logger writers appropriate for that
    # environment which can be constructed with no extra configuration data.
    # In practice this just means a $stdout stream writer in development mode.
    #
    def self.set_up_basic_logging

      @@external_logger = false
      @@logger          = Hoodoo::Logger.new

      # RACK_ENV "test" and "development" environments have debug level
      # logging. Other environments have info-level logging.

      if self.environment.test? || self.environment.development?
        @@logger.level = :debug
      else
        @@logger.level = :info
      end

      # The only environment that gets a simple writer we can create right
      # now is "development", which always logs to stdout.

      if self.environment.development?
        @@logger.add( Hoodoo::Logger::StreamWriter.new( $stdout ) )
      end
    end

    private_class_method( :set_up_basic_logging )

    # Private class method.
    #
    # Assuming ::set_up_basic_logging has previously run, add in a file
    # writer if in a test environment, or if in any other environment
    # without an AMQP based queue available.
    #
    # The method does nothing if an external logger is in use.
    #
    # +base_path+:: Path to folder to use for logs; file "{environment}.log"
    #               may be written inside.
    #
    def self.add_file_logging( base_path )
      return if @@external_logger == true

      if self.environment.test? || self.on_queue? == false
        log_path    = File.join( base_path, "#{ self.environment }.log" )
        file_writer = Hoodoo::Logger::FileWriter.new( log_path )

        @@logger.add( file_writer )
      end
    end

    private_class_method( :add_file_logging )

    # Private class method.
    #
    # Assuming ::set_up_basic_logging has previously run, add in an Alchemy
    # based queue writer if in a non-test environment with an AMQP based queue
    # available.
    #
    # The method does nothing if an external logger is in use.
    #
    # +alchemy+:: A valid Alchemy endpoint instance upon which #send_message
    #             will be invoked, to send logging messages on to the queue.
    #
    def self.add_queue_logging( alchemy )
      return if @@external_logger == true

      if self.environment.test? == false && self.on_queue?
        alchemy_queue_writer = Hoodoo::Services::Middleware::AMQPLogWriter.new( alchemy )

        @@logger.add( alchemy_queue_writer )
      end
    end

    private_class_method( :add_queue_logging )

    # Given a Rack environment, find the Alchemy endpoint and if there is one,
    # use this to initialize queue logging.
    #
    # +env+:: Rack 'env' parameter from e.g. Rack's invocation of #call.
    #
    def enable_alchemy_logging_from( env )
      alchemy = env[ 'alchemy.service' ]

      unless alchemy.nil? || defined?( @@alchemy )
        @@alchemy = alchemy
        self.class.send( :add_queue_logging, @@alchemy ) unless @@alchemy.nil?
      end
    end

    # Build common log information for the 'data' part of a payload based
    # on the given interaction. Returned as a Hash with Symbol keys.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction describing a
    #                 request. A +context+ and +interaction_id+ are expected.
    #                 The +target_interface+ and +requested_action+ are
    #                 optional and if present result in a <tt>:target</tt>
    #                 entry in the returned Hash. The +context.session+ value
    #                 if present will be included in a <tt>:session</tt> entry;
    #                 if verbose logging is enabled this will be quoted in
    #                 full, else only identity-related parts are recorded.
    #
    def build_common_log_data_for( interaction )

      session   = interaction.context.session
      interface = interaction.target_interface
      action    = interaction.requested_action

      data = {
        :id             => Hoodoo::UUID.generate(),
        :interaction_id => interaction.interaction_id
      }

      unless session.nil?
        if self.class.verbose_logging?
          data[ :session ] = session.to_h
        else
          data[ :session ] =
          {
            'session_id'           => session.session_id,
            'caller_id'            => session.caller_id,
            'caller_version'       => session.caller_version,
            'caller_identity_name' => session.caller_identity_name,
            'caller_fingerprint'   => session.caller_fingerprint,
            'identity'             => Hoodoo::Utilities.stringify( ( session.identity || {} ).to_h() )
          }
        end
      end

      unless interface.nil? || action.nil?
        data[ :target ] = {
          :resource => ( interface.resource || '' ).to_s,
          :version  =>   interface.version,
          :action   => ( action || '' ).to_s,
        }
      end

      return data
    end

    # This is part of the formalised structured logging interface upon which
    # external entities might depend. Change with care.
    #
    # For a given interaction, log the response *after the fact* of calling
    # a resource implementation, using the target interface's resource name
    # for the structured log entry's "component" field.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance for
    #                 the interaction currently being logged.
    #
    def log_call_result( interaction )

      context   = interaction.context
      interface = interaction.target_interface
      action    = interaction.requested_action

      # In #respond_for, error logging is handled. Since we generate a UUID
      # up front for errors (since a UUID is returned), we must not log under
      # that UUID twice. So in auto-log, only log success cases. Leave the
      # last-bastion-of-response that is #respond_for to deal with the rest.
      #
      return if ( context.response.halt_processing? )

      data = build_common_log_data_for( interaction )

      # Don't bother logging list responses - they could be huge - instead
      # log all list-related parameters from the inbound request. At least
      # we don't have to worry about security in that case.
      #
      # For other kinds of data, check the secure actions to see if the body
      # should be included.
      #
      # TODO: This uses deprecated accessors into the "context.request.list"
      #       object, but it keeps the code simple. It'd be nice to just have
      #       e.g. "data[ :list ] = context.request.list.to_h()" but the
      #       change in log output format might break dependent clients.

      if context.response.body.is_a?( ::Array )
        attributes       = %i( list_offset list_limit list_sort_data list_search_data list_filter_data embeds references )
        data[ :payload ] = {}

        attributes.each do | attribute |
          data[ attribute ] = context.request.send( attribute )
        end
      else
        secure = true

        unless interface.nil? || action.nil?
          secure_log_actions = interface.secure_log_for()
          secure_type        = secure_log_actions[ action ]

          # Allow body logging if there's no security specified for this action
          # or the security is specified for the request only (since we log the
          # response here).
          #
          # That means values of :both or :response will leave secure untouched,
          # as will any other unexpected value that might get specified.

          secure = false if secure_type.nil? || secure_type == :request
        end

        unless secure
          data[ :payload ] = context.response.body
        end
      end

      @@logger.report(
        :info,
        interface.resource,
        "middleware_#{ action }",
        data
      )
    end

    # This is part of the formalised structured logging interface upon which
    # external entities might depend. Change with care.
    #
    # For a given service interface, an implementation of which is receiving
    # a given action under the given request context, log the response *after
    # the fact* of calling the implementation, using the target interface's
    # resource name for the structured log entry's "component" field.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance for
    #                 the interaction currently being logged.
    #
    def log_outbound_response( interaction, rack_data )

      level = interaction.context.response.halt_processing? ? :error : :info
      data  = build_common_log_data_for( interaction )

      data[ :payload ] = {
        :http_status_code => rack_data[ 0 ].to_i,
        :http_headers     => rack_data[ 1 ]
      }

      secure    = true
      interface = interaction.target_interface
      action    = interaction.requested_action

      unless interface.nil? || action.nil?
        secure_log_actions = interface.secure_log_for()
        secure_type = secure_log_actions[ action ]

        # Allow body logging if there's no security specified for this action
        # or the security is specified for the request only (since we log the
        # response here).
        #
        # That means values of :both or :response will leave secure untouched,
        # as will any other unexpected value that might get specified.

        secure = false if secure_type.nil? || secure_type == :request
      end

      if secure == false || level == :error
        body = String.new
        rack_data[ 2 ].each { | thing | body << thing.to_s }

        if interaction.context.response.halt_processing?
          begin
            # Error cases should be infrequent, so we can "be nice" and re-parse
            # the returned body for structured logging only. We don't do this for
            # successful responses as we assume those will be much more frequent
            # and the extra parsing step would be heavy overkill for a log.
            #
            # This also means we can (in theory) extract the intended resource
            # UUID and include that in structured log data to make sure any
            # persistence layers store the item as an error with the correct ID.

            body = ::JSON.parse( body )

            uuid = body[ 'id' ]
            data[ :id ] = uuid unless uuid.nil?
          rescue
          end

        else
          body = body[ 0 .. ( MAXIMUM_LOGGED_RESPONSE_SIZE - 1 ) ] << '...' if ( body.size > MAXIMUM_LOGGED_RESPONSE_SIZE )

        end

        data[ :payload ][ :response_body ] = body
      end

      @@logger.report(
        level,
        :Middleware,
        :outbound,
        data
      )
    end

    # Log a debug message. Pass optional extra arguments which will be used as
    # strings that get appended to the log message.
    #
    # THIS IS INSECURE. Sensitive data might be logged. DO NOT USE IN DEPLOYED
    # ENVIRONMENTS. At the time of writing, Hoodoo ensures this by only using
    # debug logging in 'development' or 'test' environments.
    #
    # Before calling, +@rack_request+ must be set up with the Rack::Request
    # instance for the call environment.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance for
    #                 the interaction currently being logged.
    #
    # *args::         Optional extra arguments used as strings to add to the
    #                 log message.
    #
    def debug_log( interaction, *args )

      # Even though the logger itself would check this itself, check and exit
      # early here to avoid object creation and string composition overheads
      # from the code that would otherwise run even in non-debug environments.

      return unless @@logger.report?( :debug )

      data = build_common_log_data_for( interaction )

      scheme         = interaction.rack_request.scheme         || 'unknown_scheme'
      host_with_port = interaction.rack_request.host_with_port || 'unknown_host'
      full_path      = interaction.rack_request.fullpath       || '/unknown_path'

      data[ :full_uri ] = "#{ scheme }://#{ host_with_port }#{ full_path }"
      data[ :payload  ] = { 'args' => args }

      @@logger.report(
        :debug,
        :Middleware,
        :log,
        data
      )
    end

    # Handle responding to Rack for a given interaction. Logs that we're
    # responding and returns #for_rack data so that in (e.g.) #call the
    # idiom can be:
    #
    #     return respond_for( ... )
    #
    # ...to log the response and return data to Rack all in one go.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction, including a
    #                 valid 'response' object if you're using that for
    #                 the response data.
    #
    # +preflight+::   Optional. If +true+, this is a CORS preflight
    #                 requires and should contain no body data; else it
    #                 is a normal response and must contain body data.
    #                 Default is +false+.
    #
    # Returns data suitable for giving directly back to Rack.
    #
    def respond_for( interaction, preflight = false )
      interaction.context.response.body = '' if preflight

      # Oddly placed code for efficiency and sanity.
      #
      # When #log_outbound_response is called below, it would make sense to
      # use its existing code path for logging errors and include a variant of
      # the "if" below to add the X-Error-Logged-Via-Alchemy HTTP header if
      # required down at that level.
      #
      # However, we want the Rack response payload all wrapped up for the log
      # and it's generated here, then passed in; somehow the logging method
      # would need to update the now-compiled Rack data, or we generate the
      # Rack data again on exit, but then the logged Rack data would be wrong.
      #
      # To solve all this, just deal with the an-error-was-logged header here,
      # before we log anything or generate Rack information.

      if (
           interaction.context.response.halt_processing? &&
           self.class.on_queue?  &&
           defined?( @@alchemy ) &&
           @@logger.include_class?( Hoodoo::Services::Middleware::AMQPLogWriter )
         )

        interaction.context.response.add_header(
          'X-Error-Logged-Via-Alchemy',
          'yes',
          true
        )
      end

      rack_data = interaction.context.response.for_rack()
      log_outbound_response( interaction, rack_data )

      return rack_data
    end

    # When a request includes an <tt>X-Deja-Vu</tt> header and a service
    # returns a result that includes any errors for creation or deletion
    # events, we detect any in the collection without a given code;
    # +generic.invalid_duplication+ for creation, or
    # +generic.not_found+ for deletion.
    #
    # If we find any then normal error handling continues, otherwise the
    # errors are cleared, an HTTP response code of 204 is setup in the
    # +response+ object and body data is cleared. <tt>X-Deja-Vu</tt> is
    # set in the response too, with a +confirmed+ value.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. May be updated
    #                 on exit with new response status code, body etc.
    #
    def remove_expected_errors_when_experiencing_deja_vu( interaction )
      interesting_code = case interaction.requested_action
        when :create
          'generic.invalid_duplication'
        when :delete
          'generic.not_found'
        else
          return
      end

      other_errors = interaction.context.response.errors.errors.detect do | error_hash |
        error_hash[ 'code' ] != interesting_code
      end

      if other_errors.nil?
        interaction.context.response.errors           = Hoodoo::Errors.new()
        interaction.context.response.http_status_code = 204
        interaction.context.response.body             = ''

        interaction.context.response.add_header(
          'X-Deja-Vu',
          "confirmed",
          true # Overwrite
        )
      end
    end

    # Announce the presence of the local resource endpoints in this service
    # to known interested parties.
    #
    # ONLY CALL AS PART OF INSTANCE CREATION (from #initialize).
    #
    # +services+:: Array of Hoodoo::Services::Discovery::ForLocal instances
    #              describing available resources in this local service.
    #
    def announce_presence_of( services )

      # Note the RARE LEGITIMATE USE of an instance variable here. It will
      # be shared across potentially many threads with the same instance
      # driven through Rack. Presence announcements to the Discoverer are
      # made only upon object initialisation and remain valid (and
      # unchanged) for its lifetime.
      #
      # A class variable is wrong, as entirely new instances of the service
      # middleware might be stood up in one process and could potentially
      # be handling different resources. This is typically only the case for
      # running tests, but *might* happen elsewhere too. In any event, we
      # don't want announcements in one instance to pollute the discovery
      # data in another (especially the records of which services were
      # announced by, and therefore must be local to, an instance).

      if self.class.on_queue?

        @discoverer ||= Hoodoo::Services::Discovery::ByFlux.new

        services.each do | service |
          interface = service.interface_class

          @discoverer.announce(
            interface.resource,
            interface.version,
            { :services => services }
          )
        end

      else

        @discoverer ||= Hoodoo::Services::Discovery::ByDRb.new

        # Rack provides no formal way to find out our host or port before a
        # request arrives, because in part it might change due to clustering.
        # For local development on an assumed single instance server, we can
        # ask Ruby itself for all Rackup::Server instances, expecting just one.
        # If there isn't just one, we rely on the Rack monkey patch or a
        # hard coded default.

        host = nil
        port = nil

        if defined?( ::Rackup ) && defined?( ::Rackup::Server )
          servers = ObjectSpace.each_object( ::Rackup::Server )

          if servers.count == 1
            server = servers.first
            host   = server.options[ :Host ]
            port   = server.options[ :Port ]
          end
        end

        host ||= @@recorded_host if defined?( @@recorded_host )
        port ||= @@recorded_port if defined?( @@recorded_port )

        # Under test, ensure a simulation of an available host and port is
        # always available for discovery-related tests.

        if ( self.class.environment.test? )
          host ||= '127.0.0.1'
          port ||= '9292'
        end

        # Announce the resource endpoints. We might not be able to announce
        # the remote availability of this endpoint if the host/port are not
        # determined; but that might just be because we are running under
        # "racksh" and we wouldn't want to announce remotely anyway.

        services.each do | service |
          interface = service.interface_class

          @discoverer.announce(
            interface.resource,
            interface.version,
            {
              :host => host,
              :port => port,
              :path => service.base_path
            }
          )
        end
      end
    end

    # Load a session from the selected Hoodoo::TransientStore on the basis of
    # a session ID header in the current interaction's Rack request data.
    #
    # On exit, the interaction context may have been updated. Be sure to
    # check +interaction.context.response.halt_processing?+ to see if
    # processing should abort and return immediately.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    def load_session_into( interaction )

      test_session = self.class.test_session()
      session      = nil
      session_id   = interaction.rack_request.env[ 'HTTP_X_SESSION_ID' ]

      if session_id != nil && ( test_session.nil? || test_session.session_id != session_id )
        session = Hoodoo::Services::Session.new(
          :storage_engine   => self.class.session_store_engine(),
          :storage_host_uri => self.class.session_store_uri(),
          :session_id       => session_id
        )

        result  = session.load_from_store!( session_id )
        session = nil if result != :ok
      elsif ( self.class.environment.test? || self.class.environment.development? )
        interaction.using_test_session()
        session = self.class.test_session()
      end

      # If there's no session and no local interfaces have any public
      # methods (everything is protected) then bail out early, as the
      # request can't possibly succeed.
      #
      if session.nil? && interfaces_have_public_methods? == false
        return interaction.context.response.add_error( 'platform.invalid_session' )
      end

      # Update the interaction's context with the new session. Since
      # the context data is exposed to service implementations, the
      # session reference is read-only; don't break that protection;
      # instead build and use a replacement context.
      #
      if session != interaction.context.session
        updated_context = Hoodoo::Services::Context.new(
          session,
          interaction.context.request,
          interaction.context.response,
          interaction
        )
        interaction.context = updated_context
      end
    end

    # Run request preprocessing - common actions that occur prior to any
    # service instance selection or service-specific processing.
    #
    # Returns +nil+ if successful.
    #
    # If the method returns something else, it's a Rack response; an early
    # and immediate response has been created. Return this (through whatever
    # call chain is necessary) as the return value for #call.
    #
    # After calling, be sure to check +@response.halt_processing?+ to
    # see if processing should abort and return immediately.
    #
    # An "inbound" code log entry is generated *without* body data for CORS
    # requests or for requests which have already generated errors. In the
    # event the request so far looks good, no inbound log entry is made in
    # order to give later processing stages a chance to determine if the
    # body data could be safely logged (since it's useful to have). Thus,
    # later processing stages will still need to make a call to
    # "monkey_log_inbound_request".
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Parts of this may
    #                 be updated on exit.
    #
    def preprocess( interaction )


      # =======================================================================
      # Additions here may require corresponding additions to the
      # inter-resource local call code.
      # =======================================================================


      # Always log the inbound request early, in case of exceptions. Body data
      # will not be logged as the interaction contains no information on the
      # target resource or action, so we won't accidentally log secure data in
      # the inbound payload (if any).

      monkey_log_inbound_request( interaction )
      set_common_response_headers( interaction )

      # Potential special-case early exit for CORS preflight.

      early_exit = deal_with_cors( interaction )
      return early_exit unless early_exit.nil?

      # If we reach here it's a normal request, not CORS preflight.

      deal_with_content_type_header( interaction )
      deal_with_language_headers( interaction )

      # Load the session and then, in the context of a loaded session, process
      # any remaining extension ("X-...") HTTP headers, checking up on secured
      # headers in passing. There's special handling for X-Assume-Identity-Of,
      # which may update the session data loaded into 'interaction' with new
      # identity information.

      load_session_into( interaction )
      deal_with_x_headers( interaction )
      deal_with_x_assume_identity_of( interaction )

      return nil
    end

    # Process the client's call. The heart of service routing and application
    # invocation. Relies entirely on data assembled during initialisation of
    # this middleware instance or during handling in #call.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    def process( interaction )


      # =======================================================================
      # Additions here may require corresponding additions to the
      # inter-resource local call code.
      # =======================================================================


      response = interaction.context.response # Convenience

      # Select a service based on the escaped URI's path. If we find none,
      # then there's no matching endpoint; badly routed request; 404. If we
      # find many, raise an exception and rely on the exception handler to
      # send back a 500.
      #
      # We try the custom routing path first, then the de facto path, then
      # give up if neither match.

      uri_path = ::CGI.unescape( interaction.rack_request.path() )

      selected_path_data = nil
      selected_services  = @@services.select do | service_data |
        path_data = process_uri_path( uri_path, service_data.routing_regexp ) ||
                    process_uri_path( uri_path, service_data.de_facto_routing_regexp )

        if path_data.nil?
          false
        else
          selected_path_data = path_data
          true
        end
      end

      if selected_services.size == 0
        return response.add_error(
          'platform.not_found',
          'reference' => { :entity_name => '' }
        )
      elsif selected_services.size > 1
        raise( 'Multiple service endpoint matches - internal server configuration fault' )
      else
        selected_service = selected_services[ 0 ]
      end

      # Otherwise, update the interaction data and response data in light
      # of the chosen service's information.

      uri_path_components, uri_path_extension = selected_path_data
      interface                               = selected_service.interface_class
      implementation                          = selected_service.implementation_instance

      interaction.target_interface            = interface
      interaction.target_implementation       = implementation

      update_response_for( interaction.context.response, interface )

      # Check for a supported, session-accessible action.

      http_method                  = interaction.rack_request.request_method
      action                       = determine_action( http_method, uri_path_components.empty? )
      interaction.requested_action = action

      # We finally have enough data to log the inbound call again, with body
      # data included if allowed by the target resource.

      monkey_log_inbound_request( interaction )

      authorisation = determine_authorisation( interaction )
      return if response.halt_processing?

      # Looks good so far, so start filling in request details.

      request                     = interaction.context.request # Convenience
      request.uri_path_components = uri_path_components
      request.uri_path_extension  = uri_path_extension

      process_query_string( interaction )

      return if response.halt_processing?

      # There should be no spurious path data for "list" or "create" actions -
      # only "show", "update" and "delete" take extra data via the URL's path.
      # Conversely, other actions require it.

      if action == :list || action == :create
        return response.add_error( 'platform.malformed',
                                   'message' => 'Unexpected path components for this action',
                                   'reference' => { :action => action } ) unless uri_path_components.empty?
      else
        return response.add_error( 'platform.malformed',
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

      body = nil
      if !interaction.rack_request.body.nil?
        body = interaction.rack_request.body.read( MAXIMUM_PAYLOAD_SIZE )

        unless ( body.nil? || body.is_a?( ::String ) ) && interaction.rack_request.body.read( MAXIMUM_PAYLOAD_SIZE ).nil?
          return response.add_error( 'platform.malformed',
                                     'message' => 'Body data exceeds configured maximum size for platform' )
        end
      end

      debug_log( interaction, 'Raw body data read successfully', body )

      if action == :create || action == :update

        parse_body_string_into( interaction, body )
        return if response.halt_processing?

        validate_body_data_for( interaction )
        return if response.halt_processing?

        if action == :create # Important! For-create-only.
          maybe_update_body_data_for( interaction )
          return if response.halt_processing?
        end

      elsif body.nil? == false && body.to_s.strip.length > 0

        return response.add_error( 'platform.malformed',
                                   'message' => 'Unexpected body data for this action',
                                   'reference' => { :action => action } )

      end

      debug_log( interaction, 'Dispatching with parsed body data', request.body )

      # Can now, if necessary, do a final check with the resource endpoint
      # for authorisation because the request data is fully populated so
      # the resource implementation's "verify" method has something to use.

      if authorisation == Hoodoo::Services::Permissions::ASK
        ask_for_authorisation( interaction )
        return if response.halt_processing?
      end

      # Finally - dispatch to service.

      dispatch( interaction )
    end

    # Dispatch a call to the given implementation, with before/after actions.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    def dispatch( interaction )

      # Set up some convenience variables

      implementation = interaction.target_implementation
      action         = interaction.requested_action
      context        = interaction.context

      # Benchmark the "inner" dispatch call

      dispatch_time = ::Benchmark.realtime do

        block = Proc.new do

          # Before/after callbacks are invoked always, even if errors are
          # added to the response object during processing. If this matters
          # to 'after' code, it must check "context.response.halt_processing?"
          # itself.

          implementation.before( context ) if implementation.respond_to?( :before )
          implementation.send( action, context ) unless context.response.halt_processing?
          implementation.after( context ) if implementation.respond_to?( :after )

        end

        if ( defined?( ::ActiveRecord ) && defined?( ::ActiveRecord::Base ) )
          ::ActiveRecord::Base.connection_pool.with_connection( &block )
        else
          block.call
        end

        if context.request.deja_vu && context.response.halt_processing?
          remove_expected_errors_when_experiencing_deja_vu( interaction )
        end

        log_call_result( interaction )

      end # "Benchmark.realtime do"

      context.response.add_header(
        'X-Service-Response-Time',
        "#{ dispatch_time.inspect } seconds",
        true # Overwrite
      )
    end

    # Run request preprocessing - common actions that occur after service
    # instance selection and service-specific processing.
    #
    # On exit, interaction data may have been updated.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    def postprocess( interaction )


      # =======================================================================
      # Additions here may require corresponding additions to the
      # inter-resource local call code.
      # =======================================================================


      # TODO: Nothing?
      #
      # This is only called on service *success*. Potentially we can hook in
      # the validation of the service's output (internal self-check) according
      # the expected returned Resource that the interface class defines (see
      # the "interface.resource" property), so long as it's defined in the
      # Hoodoo::Data::Resources collection (or extend the DSL to take a Class).
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
    # If successful, updates the given interaction data with the request
    # content type and encoding.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Updated on exit.
    #
    def deal_with_content_type_header( interaction )

      # An in-the-wild Content-Type header value of
      # "application/json; charset=utf-8, application/x-www-form-urlencoded"
      # from Postman caused Rack 1.6.4 to break and raise an exception. Trap
      # any exceptions from the Rack request calls below and assume that they
      # indicate a malformed header.
      #
      begin
        content_type     = interaction.rack_request.media_type
        content_encoding = interaction.rack_request.content_charset
      rescue
        interaction.context.response.errors.add_error(
          'platform.malformed',
          'message' => "Content-Type '#{ interaction.rack_request.content_type || "<unknown>" }' is malformed"
        )

        return
      end

      content_type.downcase!     unless content_type.nil?
      content_encoding.downcase! unless content_encoding.nil?

      unless SUPPORTED_MEDIA_TYPES.include?( content_type ) &&
             SUPPORTED_ENCODINGS.include?( content_encoding )

        interaction.context.response.errors.add_error(
          'platform.malformed',
          'message' => "Content-Type '#{ interaction.rack_request.content_type || "<unknown>" }' does not match supported types '#{ SUPPORTED_MEDIA_TYPES }' and/or encodings '#{ SUPPORTED_ENCODINGS }'"
        )

        # Avoid incorrect Content-Type in responses, which otherwise "inherits"
        # from inbound type and encoding.
        #
        content_type = content_encoding = nil

      end

      interaction.requested_content_type     = content_type
      interaction.requested_content_encoding = content_encoding
    end

    # Extract the +Content-Language+ header value from the client, or if that
    # is missing, +Accept-Language+. Uses it, or a default of "en-nz",
    # converts to lower case and sets the value as the interaction's request's
    # locale value.
    #
    # We support neither a list of preferences nor "qvalues", so if there is
    # a list, we only take the first item; if there is a value, we strip it
    # leaving just the language part, e.g. "en-gb".
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Updated on exit.
    #
    def deal_with_language_headers( interaction )
      lang = interaction.rack_request.env[ 'HTTP_CONTENT_LANGUAGE' ]
      lang = interaction.rack_request.env[ 'HTTP_ACCEPT_LANGUAGE' ] if lang.nil? || lang.empty?

      unless lang.nil? || lang.empty?
        # E.g. "Accept-Language: da, en-gb;q=0.8, en;q=0.7" => 'da'
        lang = lang.split( ',' )[ 0 ]
        lang = lang.split( ';' )[ 0 ]
      end

      lang = 'en-nz' if lang.nil? || lang.empty?
      interaction.context.request.locale = lang.downcase
    end

    # Extract all +X-Foo+ headers from Hoodoo::Client::Headers'
    # +HEADER_TO_PROPERTY+ and store relevant information in the request data
    # based on the header mappings. Security checks are done for secured
    # headers. Validation is performed according to validation Procs in the
    # mappings.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Updated on exit.
    #
    def deal_with_x_headers( interaction )

      # Set up some convenience variables

      session  = interaction.context.session
      rack_env = interaction.rack_request.env
      request  = interaction.context.request

      Hoodoo::Client::Headers::HEADER_TO_PROPERTY.each do | rack_header, description |

        header_value = rack_env[ rack_header ]
        next if header_value.nil?

        # Don't do anything else if this header is secured but prohibited.

        real_header = description[ :header ]

        if description[ :secured ] == true &&
           (
             session.respond_to?( :scoping ) == false ||
             session.scoping.respond_to?( :authorised_http_headers ) == false ||
             session.scoping.authorised_http_headers.respond_to?( :include? ) == false ||
             (
               session.scoping.authorised_http_headers.include?( rack_header ) == false &&
               session.scoping.authorised_http_headers.include?( real_header ) == false
             )
           )

          interaction.context.response.errors.add_error( 'platform.forbidden' )

          return # EARLY EXIT
        end

        # If we reach here the header is either not secured, or is permitted.
        # Check to see if the value is OK.

        property_writer = description[ :property_writer ]
        property_value  = description[ :property_proc   ].call( header_value )

        if property_value.nil?
          interaction.context.response.errors.add_error(
            'generic.malformed',
            {
              :message   => "#{ real_header } header value '#{ header_value }' is invalid",
              :reference => { :header_name => real_header }
            }
          )

          return # EARLY EXIT
        end

        # All good!

        request.send( property_writer, property_value )

      end
    end

    # The X-Assume-Identity-Of secured HTTP header allows a caller to specify
    # values for parts of their session's "identity" section, based upon
    # permitted values described in their session's "scoping" section. This
    # method assumes that the permission to use the header in the first place
    # has already been established by #deal_with_x_headers and, as a result,
    # relevant property information has been written into the request object.
    #
    # The header's value is parsed and checked against the session scoping
    # data. If everything looks good, the loaded session's identity is
    # updated accordingly. If there are any problems, one or more errors will
    # be added to the interaction's context's response object.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Updated on exit.
    #
    def deal_with_x_assume_identity_of( interaction )

      # Header not in use? Exit now.
      #
      return if interaction.context.request.assume_identity_of.nil?

      input_hash = interaction.context.request.assume_identity_of
      rules_hash = interaction.context.session.scoping.authorised_identities rescue {}

      if ( input_hash.empty? )
        interaction.context.response.errors.add_error(
          'generic.malformed',
          {
            :message   => "X-Assume-Identity-Of header value is malformed",
            :reference => { :header_value => ( interaction.context.request.assume_identity_of rescue 'unknown' ) }
          }
        )
      end

      return if interaction.context.response.halt_processing?

      identity_overrides = validate_x_assume_identity_of( interaction, input_hash, rules_hash )

      return if interaction.context.response.halt_processing?

      identity_overrides.each do | key, value |
        interaction.context.session.identity.send( "#{ key }=", value )
      end
    end

    # Back-end to #deal_with_x_assume_identity_of which recursively processes
    # a rule set against a value from the X-Assume-Identity-Of HTTP header and
    # either updates the interaction's context's response object with error
    # details if anything is wrong, or returns a flat Hash of keys and values
    # to (over-)write in the session's identity section.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Will be updated on
    #                 exit if errors occur.
    #
    # +input_hash+::  Header value for X-Assume-Identity-Of processed into a
    #                 flat Hash of String keys and String values.
    #
    # +rules_hash+::  Rules Hash from the session scoping data - usually its
    #                 "authorised_identities" key - or a sub-hash from nested
    #                 data during recursive calls.
    #
    # +recursive+::   Top-level callers MUST omit this parameter. Internal
    #                 recursive callers MUST set this to +true+.
    #
    def validate_x_assume_identity_of( interaction, input_hash, rules_hash, recursive = false )
      identity_overrides = {}

      unless rules_hash.is_a?( Hash )
        interaction.context.response.errors.add_error(
          'generic.malformed',
          :message => "X-Assume-Identity-Of header cannot be processed because of malformed scoping rules in Session's associated Caller",
        )

        return nil
      end

      rules_hash.each do | rules_key, rules_value |

        next unless input_hash.has_key?( rules_key )
        input_value = input_hash[ rules_key ]

        unless input_value.is_a?( String )
          raise "Internal error - internal validation input value for X-Assume-Identity-Of is not a String"
        end

        if rules_value.is_a?( Array )
          if rules_value.include?( input_value )
            identity_overrides[ rules_key ] = input_value
          else
            interaction.context.response.errors.add_error(
              'platform.forbidden',
              {
                :message   => "X-Assume-Identity-Of header value requests a prohibited identity quantity",
                :reference =>
                {
                  :name  => rules_key,
                  :value => input_value
                }
              }
            )
            return nil
          end

        elsif rules_value == '*'
          identity_overrides[ rules_key ] = input_value

        elsif rules_value.is_a?( Hash )
          if rules_value.has_key?( input_value )
            identity_overrides[ rules_key ] = input_value

            nested_identity_overrides = validate_x_assume_identity_of(
              interaction,
              input_hash,
              rules_value[ input_value ],
              true
            )

            return if nested_identity_overrides.nil?
            identity_overrides.merge!( nested_identity_overrides )

          else
            interaction.context.response.errors.add_error(
              'platform.forbidden',
              {
                :message   => "X-Assume-Identity-Of header value requests a prohibited identity quantity",
                :reference =>
                {
                  :name  => rules_key,
                  :value => input_value
                }
              }
            )
            return nil

          end

        else
          interaction.context.response.errors.add_error(
            'generic.malformed',
            :message => "X-Assume-Identity-Of header cannot be processed because of malformed scoping rules in Session's associated Caller",
          )
          return nil

        end
      end

      unless recursive || ( input_hash.keys - identity_overrides.keys ).empty?
        interaction.context.response.errors.add_error(
          'platform.forbidden',
          {
            :message   => "X-Assume-Identity-Of header value requests prohibited identity name(s)",
            :reference =>
            {
              :names => ( input_hash.keys - identity_overrides.keys ).sort().join( ',' )
            }
          }
        )
        return nil
      end

      return identity_overrides
    end

    # Preprocessing stage that sets up common headers required in any response.
    # May vary according to inbound content type requested. If processing was
    # aborted early (e.g. missing inbound Content-Type) we may fall to defaults.
    #
    # (At the time of writing, platform documentations say we're JSON only - but
    # there's an strong chance of e.g. XML representation being demanded later).
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Updated on exit.
    #
    def set_common_response_headers( interaction )
      interaction.context.response.add_header( 'X-Interaction-ID', interaction.interaction_id )
      interaction.context.response.add_header( 'Content-Type', "#{ interaction.requested_content_type || 'application/json' }; charset=#{ interaction.requested_content_encoding || 'utf-8' }" )
    end

    # Simplistic CORS preflight handler.
    #
    # * http://www.w3.org/TR/cors/
    # * http://www.w3.org/TR/cors/#preflight-request
    # * http://enable-cors.org
    # * https://developer.mozilla.org/en-US/docs/Web/HTTP/Access_control_CORS
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    # Returns +nil+ if the request can continue to be processed, else an early
    # exit CORS response has already been generated; processing should stop now.
    #
    def deal_with_cors( interaction )
      headers = interaction.rack_request.env
      origin  = headers[ 'HTTP_ORIGIN' ]

      unless ( origin.nil? )
        if interaction.rack_request.request_method == 'OPTIONS'
          requested_method  = headers[ 'HTTP_ACCESS_CONTROL_REQUEST_METHOD' ]
          requested_headers = headers[ 'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' ]

          if ALLOWED_HTTP_METHODS.include?( requested_method )

            # We just parrot back the origin and requested headers as
            # any are theoretically possible. Other security layers
            # deal with, ignore, or reject interesting HTTP headers.

            set_cors_preflight_response_headers( interaction, origin, requested_headers )

          else
            interaction.context.response.errors.add_error( 'platform.method_not_allowed' )

          end

          # The early exit means only secure logging (earlier) is
          # done. Insecure logging with body data is not performed,
          # just in case the CORS inbound request contains anything
          # daft which could count as secure information.

          return respond_for( interaction, true )

        else
          set_cors_normal_response_headers( interaction, origin )

        end
      end

      return nil
    end

    # Preprocessing stage that sets up CORS response headers in response to a
    # normal (or preflight) CORS response.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    # +origin+::      Value of inbound request's "Origin" HTTP header.
    #
    def set_cors_normal_response_headers( interaction, origin )
      interaction.context.response.add_header( 'Access-Control-Allow-Origin', origin )
    end

    # Preprocessing stage that sets up CORS response headers in response to a
    # preflight CORS response, based on given inbound headers.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    # +origin+::      Value of inbound request's "Origin" HTTP header.
    #
    # +headers+::     Value of inbound request's
    #                 "Access-Control-Request-Headers" HTTP header.
    #
    def set_cors_preflight_response_headers( interaction, origin, headers )

      set_cors_normal_response_headers( interaction, origin )

      # We don't try and figure out a target resource interface and give back
      # just the verbs it supports in preflight; too much trouble; just list
      # all *possible* supported methods.

      interaction.context.response.add_header(
        'Access-Control-Allow-Methods',
        ALLOWED_HTTP_METHODS.to_a.join( ', ' )
      )

      # Same for HTTP headers. Just allow whatever was requested. Other layers
      # will read, ignore, or reject interesting HTTP headers.

      interaction.context.response.add_header(
        'Access-Control-Allow-Headers',
        headers
      )

      # No "Access-Control-Expose-Headers" is set. We don't expose *any* of
      # the custom response headers to untrusted JavaScript code - not even
      # the Interaction ID.

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
        remaining_path_components = match_data[ 2 ].split( '/' ).reject { | str | str == '' }
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
    # method. This doesn't say anything about whether or not a particular
    # endpoint happens to support that action - it just maps HTTP verb to
    # action.
    #
    # See also #determine_authorisation.
    #
    # +http_method+:: Inbound method as a string, e.g. +'POST'+. Upper or
    #                 lower case.
    #
    # +get_is_list+:: If +true+, treat GET methods as +:list+, else as
    #                 +:show+. This is often determined on the basis of e.g.
    #                 path components after the endpoint part of the URI path
    #                 being absent or present.
    #
    # Returns the action as a Symbol - see ALLOWED_ACTIONS.
    #
    def determine_action( http_method, get_is_list )
      http_method = ( http_method || '' ).upcase

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

      return action
    end

    # Determine the authorisation / permission to perform a particular
    # action.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    # Returns:
    #
    # * Hoodoo::Services::Permissions::ALLOW - the action is allowed.
    #
    # * +nil+ - the action was prohibited. The given +response+ was
    #   with an appropriate error message (e.g. "invalid session",
    #   "forbidden" etc.).
    #
    # * Hoodoo::Services::Permissions::ASK - the caller MUST check with
    #   the target endpoint's implementation to see if the action is
    #   allowed by calling #ask_for_authorisation at some point later in
    #   processing when the information this needs is available.
    #
    def determine_authorisation( interaction )

      # Set up some convenience variables

      interface = interaction.target_interface
      action    = interaction.requested_action
      session   = interaction.context.session
      response  = interaction.context.response

      # Check authorisation

      result = nil

      if interface.public_actions.include?( action )

        # Public action; no need to check anything else, it's allowed,
        # session or no session.

        result = Hoodoo::Services::Permissions::ALLOW

      else

        # The action isn't public; so unless it is declared as a protected
        # action, it isn't supported by this endpoint. If supported, check
        # session and permissions.

        if interface.actions.include?( action )

          if session.nil?
            response.add_error( 'platform.invalid_session' )
          elsif session.permissions.nil?
            response.add_error( 'platform.forbidden' )
          else
            permission = session.permissions.permitted?( interface.resource, action )

            if permission == Hoodoo::Services::Permissions::DENY
              response.add_error( 'platform.forbidden' )
            else
              result = permission
            end
          end

        else

          http_method = interaction.rack_request.request_method

          response.add_error(
            'platform.method_not_allowed',
            'message' => "Service endpoint '/v#{ interface.version }/#{ interface.endpoint }' does not support HTTP method '#{ ( http_method || '<unknown>' ).upcase }' yielding action '#{ action }'"
          )

        end
      end

      return result
    end

    # As a service for authorisation for a particular action given
    # the request and session context data provided.
    #
    # Calls the Hoodoo::Services::Implementation#verify method in the
    # target implementation. Expects a conforming response; anything
    # that isn't Hoodoo::Services::Permissions::ALLOW is treated as
    # Hoodoo::Services::Permissions::DENY.
    #
    # Parameters:
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    # Returns:
    #
    # * Hoodoo::Services::Permissions::ALLOW - the action is allowed.
    #
    # * +nil+ - the action was prohibited. The given +response+ was
    #   with an appropriate error message (e.g. "invalid session",
    #   "forbidden" etc.).
    #
    def ask_for_authorisation( interaction )

      permission = interaction.target_implementation.verify(
                     interaction.context,
                     interaction.requested_action
                   )

      if permission == Hoodoo::Services::Permissions::ALLOW
        return permission
      else
        interaction.context.response.add_error( 'platform.forbidden' )
        return nil
      end
    end

    # Update a Hoodoo::Services::Response instance for making a call to
    # the given Hoodoo::Services::Interface, setting up error description
    # information. Other initialisation is left to the caller.
    #
    # +response+::  Hoodoo::Services::Response instance to update.
    # +interface+:: Hoodoo::Services::Interface for which the request is being
    #               constructed. Custom error descriptions from that
    #               interface, if any, are included in the response object's
    #               error collection data.
    #
    def update_response_for( response, interface )
      unless interface.errors_for.nil?
        response.errors = Hoodoo::Errors.new( interface.errors_for )
      end
    end

    # Process query string data for list actions. Only call if there's a list
    # action being requested.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    # The interaction's request data will be updated with list parameter
    # information if successful. The interaction's response data will be
    # updated with error information if anything is wrong.
    #
    def process_query_string( interaction )

      query_string = interaction.rack_request.query_string

      # The 'decode' call produces an array of two-element arrays, the first
      # being the key and next being the value, already CGI unescaped once.
      #
      # On some Ruby versions bad data here can cause an exception, so there's
      # a catch-all "rescue" at the end of the function to return a 'malformed'
      # response if necessary.

      query_data = URI.decode_www_form( query_string )

      # Convert to a unified Hash of non-duplicated keys yielding Arrays of
      # *not* unique values ('true' in second parameter => allow duplicates).

      query_hash = Hoodoo::Utilities.collated_hash_from( query_data, true )

      # Some query hash entries accept either multiple repeats in the query
      # string, or comma-separated values in a single query string entry.
      # For example:
      #
      #   &sort=name&sort=created_at&direction=asc&direction=asc
      #
      # ...versus:
      #
      #   &sort=name,created_at&direction=asc,desc
      #
      # Further, search and filter strings should have been double-encoded
      # so still require a decode pass before we can process things as above.

      # First, split any input query strings on "," for supported keys.

      %w{ sort direction search filter _embed _reference }.each do | key |
        value = query_hash[ key ]
        unless value.nil?
          value.map! do | possible_csv_to_split |
            possible_csv_to_split.split( ',' )
          end
        end
      end

      # Flatten remaining sub-arrays and make sure values are unique. Sort
      # keys and sort directions are deduplicated intelligently within the
      # #process_query_hash method.

      query_hash.each do | key, value |
        value.flatten!
        value.uniq! unless key == 'sort' || key == 'direction'
      end

      # For search and filter strings, decode the key/value pairs as a
      # unified string with the Hash-converted result written back.

      %w{ search filter }.each do | key |
        value = query_hash[ key ]
        unless value.nil?
          query_hash[ key ] = Hash[ URI::decode_www_form( value.join( '&' ) ) ]
        end
      end

      # For some other parameters, array values just don't make sense, so
      # take the *last* of these, so that subsequently-specified values are
      # overriding previously-specified values, as a caller might expect.

      %w{ offset limit }.each do | key |
        value = query_hash[ key ]
        unless value.nil?
          query_hash[ key ] = value.last
        end
      end

      return process_query_hash( interaction, query_hash )
    end

    # Process a hash of URI-decoded form data in the same way as
    # #process_query_string (and used as a back-end for that). Nested search
    # and filter strings should be decoded as nested hashes. Nested _embed and
    # _reference lists should be stored as arrays. Other values may be Strings
    # or Arrays. All Hash keys must be Strings.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    # +query_hash+::  Hash of data derived from query string - see
    #                 #process_query_string.
    #
    # The interaction's request data will be updated with list parameter
    # information if successful. The interaction's response data will be
    # updated with error information if anything is wrong.
    #
    def process_query_hash( interaction, query_hash )

      # Set up some convenience variables

      interface = interaction.target_interface
      request   = interaction.context.request
      response  = interaction.context.response

      # Process the query hash

      allowed  = ALLOWED_QUERIES_ALL
      allowed += ALLOWED_QUERIES_LIST if interaction.requested_action == :list

      unrecognised_query_keys = query_hash.keys - allowed
      malformed = unrecognised_query_keys

      limit = Hoodoo::Utilities::to_integer?( query_hash[ 'limit' ] || interface.to_list.limit )
      malformed << :limit if limit.nil? || limit < 1

      offset = Hoodoo::Utilities::to_integer?( query_hash[ 'offset' ] || 0 )
      malformed << :offset if offset.nil? || offset < 0

      # In essence the code below is rationalising sort and direction lists as
      # follows:
      #
      #     SORT     DIRECTION
      #     ==================
      #   0 created
      #   => created with default direction for sort key 'created'
      #
      #   0          desc
      #   => default sort key with 'desc' order
      #
      #   0 created  asc
      #   1 name     desc
      #   2 title
      #   => mismatched sort vs direction list length
      #
      #   0 created asc
      #   1         desc
      #   => mismatched sort vs direction list length

      sort_keys       = query_hash[ 'sort'      ] || [ interface.to_list.default_sort_key ]
      sort_directions = query_hash[ 'direction' ] || []

      # For inter-resource calls, historical callers might provide a sort key
      # and/or direction as a String not Array, so promote and flatten.

      sort_keys       = [ sort_keys       ] if sort_keys.is_a?( String )
      sort_directions = [ sort_directions ] if sort_directions.is_a?( String )

      # 2015-07-03 (ADH): This used to just read "sort_directions.size >
      # sort_keys.size", to match the big comment a few lines above. During
      # pull request review though it was decided that we'd remove the
      # ambiguity in mismatched sort key or direction lists entirely and
      # require them both (when there's more than one) in equal numbers.
      #
      # We have to allow someone to just specify a direction without the sort
      # key for the single-use case (i.e. change to "created_at asc") else the
      # change would break any clients that already use such parameters.
      #
      # The originally intended, more permissive, default-orientated behaviour
      # can of course be restored by just changing this "if" back.
      #
      if ( sort_keys.size > 1 || sort_directions.size > 1 ) && sort_directions.size != sort_keys.size
        malformed << :direction
      else
        sort_keys.each_with_index do | sort_key, index |
          unless interface.to_list.sort[ sort_key ].is_a?( Set )
            malformed << :sort
            break
          end

          sort_direction = sort_directions[ index ] || interface.to_list.sort[ sort_key ].first

          unless interface.to_list.sort[ sort_key ].include?( sort_direction )
            malformed << :direction
            break
          end

          sort_directions[ index ] = sort_direction
        end
      end

      search           = query_hash[ 'search' ] || {}
      framework_search = FRAMEWORK_QUERY_DATA.keys - interface.to_list.do_not_search
      bad_search_keys  = search.keys - framework_search - interface.to_list.search

      framework_search.each do | search_key |
        next unless search.has_key?( search_key )

        search_value = search[ search_key ]
        validator    = FRAMEWORK_QUERY_DATA[ search_key ]
        canonical    = validator.call( search_value )

        if canonical.nil?
          bad_search_keys << search_key
        else
          search[ search_key ] = canonical
        end
      end

      filter           = query_hash[ 'filter' ] || {}
      framework_filter = FRAMEWORK_QUERY_DATA.keys - interface.to_list.do_not_filter
      bad_filter_keys  = filter.keys - framework_filter - interface.to_list.filter

      framework_filter.each do | filter_key |
        next unless filter.has_key?( filter_key )

        filter_value = filter[ filter_key ]
        validator    = FRAMEWORK_QUERY_DATA[ filter_key ]
        canonical    = validator.call( filter_value )

        if canonical.nil?
          bad_filter_keys << filter_key
        else
          filter[ filter_key ] = canonical
        end
      end

      embeds           = query_hash[ '_embed' ] || []
      bad_embeds       = embeds - interface.embeds

      references       = query_hash[ '_reference' ] || []
      bad_references   = references - interface.embeds # (sic.)

      malformed <<     "search: #{ bad_search_keys.join( ', ' ) }" unless bad_search_keys.empty?
      malformed <<     "filter: #{ bad_filter_keys.join( ', ' ) }" unless bad_filter_keys.empty?
      malformed <<     "_embed: #{ bad_embeds.join( ', ' ) }"      unless bad_embeds.empty?
      malformed << "_reference: #{ bad_references.join( ', ' ) }"  unless bad_references.empty?

      return response.add_error(
        'platform.malformed',
        'message' => "One or more malformed or invalid query string parameters",
        'reference' => { :including => malformed.join( ', ' ) }
      ) unless malformed.empty?

      sort_data = {}
      sort_keys.each_with_index do | sort_key, index |
        sort_data[ sort_key ] = sort_directions[ index ]
      end

      request.list.offset      = offset
      request.list.limit       = limit
      request.list.sort_data   = sort_data
      request.list.search_data = search
      request.list.filter_data = filter
      request.embeds           = embeds
      request.references       = references
    end

    # Safely parse the client payload in the context of the defined content
    # type (#deal_with_content_type_header must have been run first).
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Response may be
    #                 updated on exit with an error, or request may be
    #                 updated with the parsed body data as a Hash.
    #
    # +body+::        Calling client request's body payload as a String.
    #
    def parse_body_string_into( interaction, body )

      content_type = interaction.requested_content_type

      begin
        case content_type
          when 'application/json'

            # Hoodoo requires Ruby 2.1 or later, else:
            # https://www.ruby-lang.org/en/news/2013/02/22/json-dos-cve-2013-0269/
            #
            payload_hash = ::JSON.parse( body )

        end

      rescue
        payload_hash = {}
        interaction.context.response.errors.add_error( 'generic.malformed' )

      end

      if payload_hash.nil?
        raise "Internal error - content type '#{ interaction.requested_content_type }' is not supported here; \#deal_with_content_type_header() should have caught that"
      end

      interaction.context.request.body = payload_hash
    end

    # For the given action and service interface, verify the given body data
    # via to-update / to-create DSL data where available. On exit, the given
    # response data may have errors added.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Response may be
    #                 updated on exit with an error, or request may be
    #                 updated with the parsed body data as a Hash.
    #
    def validate_body_data_for( interaction )

      # Set up some convenience variables

      interface = interaction.target_interface
      action    = interaction.requested_action
      response  = interaction.context.response
      body      = interaction.context.request.body

      # Work out which verification schema to use

      verification_object = if ( action == :create )
        interface.to_create()
      else
        interface.to_update()
      end

      # Verify the inbound parameters either via to-create/to-update schema
      # or, if absent, at least make sure prohibited fields are absent.

      if ( verification_object.nil? )

        requested_fields = body.keys
        union            = PROHIBITED_INBOUND_FIELDS & requested_fields

        unless union.empty?
          response.errors.add_error(
            'generic.invalid_parameters',
            'message' => 'Body data contains unrecognised or prohibited fields',
            'reference' => { :fields => union.join( ', ' ) }
          )
        end

      else

        # 'false' => validate as type-only, not a resource (no ID, kind etc.)
        #
        result = verification_object.validate( body, false )

        if result.has_errors?
          response.errors.merge!( result )
        else
          # Strip out unexpected/unrecognised fields and sanitise the input
          # in addition to general validation.
          #
          # At the time of writing, it makes more sense to warn callers if
          # they send stuff that is not recognised; e.g. they might have
          # misread the API and be trying to patch field "id", or change a
          # field that's in the resource representation and maybe used for
          # a "create" but can't be subsequently modified; or they might be
          # using fields that are defined in a newer version of the API,
          # but are talking to a service that doesn't implement it.
          #
          # Thus, complain if the sanitised body differs from the input.

          rendered = verification_object.render( body ) # May add default fields
          merged   = body.merge( rendered )

          if ( merged != rendered )
            deep_dup    = Hoodoo::Utilities.deep_dup( body )
            deep_merged = Hoodoo::Utilities.deep_merge_into( deep_dup, rendered )
            diff        = Hoodoo::Utilities.hash_diff( deep_merged, rendered )
            paths       = Hoodoo::Utilities.hash_key_paths( diff )

            response.errors.add_error(
              'generic.invalid_parameters',
              'message' => 'Body data contains unrecognised or prohibited fields',
              'reference' => { :fields => paths.join( ', ' ) }
            )
          end
        end
      end
    end

    # Some HTTP headers or other request features may give us reason to modify
    # inbound body data.
    #
    # * Currently, this is only ever done for a "create" action (POST); never
    #   call here for any other action / HTTP method.
    #
    # * Secured header checking must already have taken place before calling.
    #
    # At present this involves just the X-Resource-UUID header. If this is
    # present and the value is non-empty, it's validated as UUID and written as
    # the body's "id" field at the top-level if OK.
    #
    # By the time this method is called, validation of the header value must
    # already have taken place (see "deal_with_x_headers").
    #
    # On exit, the interaction's request's body may be updated, or the
    # response's error collection may be updated rejecting the request on
    # the grounds of an invalid UUID.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    def maybe_update_body_data_for( interaction )
      return unless interaction.rack_request.env.has_key?( 'HTTP_X_RESOURCE_UUID' )

      required_item_uuid = interaction.rack_request.env[ 'HTTP_X_RESOURCE_UUID' ]
      interaction.context.request.body[ 'id' ] = required_item_uuid
    end

    # Record an exception in a given response object, overwriting any previous
    # error data if present.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Response will be
    #                 updated on exit with just the exception error.
    #
    # +exception+::   The Exception instance to record.
    #
    # Returns a "for Rack" representation of the whole response.
    #
    def record_exception( interaction, exception )
      reference = {
        :exception => exception.message
      }

      unless self.class.environment.production? || self.class.environment.red?
        reference[ :backtrace ] = exception.backtrace.join( " | " )
      end

      # A service can rewrite this field with a different object, leading
      # to an exception within the exception handler; so use a new one!
      #
      interaction.context.response.errors = Hoodoo::Errors.new()

      return interaction.context.response.add_error(
        'platform.fault',
        'message' => exception.message,
        'reference' => reference
      )
    end

    # Take a Hoodoo::Errors instance constructed from, or obtained via
    # a call to another service (inter-resource local or remote call) and
    # translate the contents to make sense when those errors are reported
    # in the context of an outer resource's response to a request.
    #
    # For example, if one resource tries to look up a reference to another
    # as part of a +show+ action, but that _referred_ resource is not found,
    # internally that would be reported via HTTP 404. This would confuse
    # callers if returned verbatim as it implies the target, outermost
    # resource wasn't found, even though it was. Instead, the 404 is turned
    # into a 422 with code/message/reference data describing the equivalent
    # "inner reference not found" condition.
    #
    def annotate_errors_from_other_resource( errors )
      # TODO - Move to an accessible shared location, e.g. Errors itself
      #        The inter-resource remote endpoint code duplicates this
      return errors
    end

    # The following must appear at the end of this class definition.

    set_up_basic_logging()

  end    # 'class Middleware'
end; end # 'module Hoodoo; module Services'
