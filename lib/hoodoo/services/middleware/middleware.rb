########################################################################
# File::    service_middleware.rb
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
require 'uri'
require 'net/http'
require 'net/https'
require 'drb/drb'

require 'hoodoo/services/services/permissions'
require 'hoodoo/services/services/session'

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
  # Alchemy endpoint (see the Alchemy and AMQEndpoint gems).
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

    # Maximum *logged* payload size.
    #
    MAXIMUM_LOGGED_PAYLOAD_SIZE = 1024

    # The default test session; a Hoodoo::Services::Session instance with the
    # following characteristics:
    #
    # Session ID::      +01234567890123456789012345678901+
    # Caller ID::       +c5ea12fb7f414a46850e73ee1bf6d95e+
    # Caller Version::  1
    # Permissions::     Default/else/"allow" to allow all actions
    # Identity::        Has +caller_id+ as its only field
    # Scoping::         Empty
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
      'session_id'     => '01234567890123456789012345678901',
      'expires_at'     => ( Time.now + 172800 ).utc.iso8601,
      'caller_version' => 1,
      'caller_id'      =>                  'c5ea12fb7f414a46850e73ee1bf6d95e',
      'identity'       => { 'caller_id' => 'c5ea12fb7f414a46850e73ee1bf6d95e' },
      'scoping'        => {},
      'permissions'    => Hoodoo::Services::Permissions.new( {
        'default' => { 'else' => Hoodoo::Services::Permissions::ALLOW }
      } ).to_h
    } )

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

    # Do we have Memcached available? If not, assume local development with
    # higher level queue services not available. Most service authors should
    # not ever need to check this.
    #
    def self.has_memcached?
      m = self.memcached_host()
      m.nil? == false && m.empty? == false
    end

    # Return a Memcached host (IP address/port combination) as a String if
    # defined in environment variable MEMCACHED_HOST (with MEMCACHE_URL also
    # accepted as a legacy fallback).
    #
    # If this returns +nil+ or an empty string, there's no defined Memcached
    # host available.
    #
    def self.memcached_host
      ENV[ 'MEMCACHED_HOST' ] || ENV[ 'MEMCACHE_URL' ]
    end

    # Are we running on the queue, else (implied) a local HTTP server?
    #
    def self.on_queue?
      q = ENV[ 'AMQ_ENDPOINT' ]
      q.nil? == false && q.empty? == false
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
    def self.logger
      @@logger # See self.set_up_basic_logging and self.set_logger
    end

    # The middleware sets up a logger itself (see ::logger) with various log
    # mechanisms set up (mostly) without service author intervention.
    #
    # If you want to completely override the middleware's logger and replace
    # it with your own at any time (not recommended), call here.
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
    # logger set up (see ::set_logger), call here to configure the folder used
    # for logs when file output is active.
    #
    # If you don't do this at least once, no log file output can occur.
    #
    # You can call more than once to output to more than one log folder.
    #
    # +base_path+:: Path to folder to use for logs; file "#{environment}.log"
    #               may be written inside (see ::environment).
    #
    def self.set_log_folder( base_path )
      self.send( :add_file_logging, base_path )
    end

    # A Hoodoo::Services::Session instance to use for tests or when no
    # local Memcached instance is known about (environment variable
    # +MEMCACHED_HOST+ is not set). The session is (eventually) read each
    # time a request is made via Rack (through #call).
    #
    # "Out of the box", DEFAULT_TEST_SESSION is used.
    #
    def self.test_session
      @@test_session
    end

    @@test_session = DEFAULT_TEST_SESSION

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
    # service. if it is running (exceptions are ignored). Existing middleware
    # instances will be invalidated. New instances must be created to re-scan
    # their services internally and (where required) inform the DRb process
    # of the endpoints.
    #
    def self.flush_services_for_test
      @@services = []
      begin
        @@drb_service.flush()
      rescue
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
          newrelic_wrapper  = service_container
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

      @@services = service_container.component_interfaces.map do | interface |

        if interface.nil? || interface.endpoint.nil? || interface.implementation.nil?
          raise "Hoodoo::Services::Middleware encountered invalid interface class #{ interface } via service class #{ service_container.class }"
        end

        # If anything uses a public interface, we need to tell ourselves that
        # the early exit session check can't be done.
        #
        interfaces_have_public_methods() unless interface.public_actions.empty?

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

          unless self.class.environment.test? || self.class.environment.development?
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
      alchemy = env[ 'rack.alchemy' ]
      unless alchemy.nil? || defined?( @@alchemy )
        @@alchemy = alchemy
        self.class.send( :add_queue_logging, @@alchemy ) unless @@alchemy.nil?
      end
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
    # Returns data suitable for giving directly back to Rack.
    #
    def respond_for( interaction )

      rack_data = interaction.context.response.for_rack()

      id   = nil
      body = ''

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
        :interaction_id => interaction.interaction_id,
        :payload        => {
          :http_status_code => rack_data[ 0 ],
          :http_headers     => rack_data[ 1 ],
          :response_body    => body
        }
      }

      data[ :id       ] = id unless id.nil?
      data[ :session  ] = interaction.context.session.to_h unless interaction.context.session.nil?
      data[ :resource ] = interaction.target_resource_for_error_reports.to_s unless interaction.target_resource_for_error_reports.nil?

      @@logger.report(
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
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance for
    #                 the interaction currently being logged.
    #
    def auto_log( interaction )

      context   = interaction.context
      interface = interaction.target_interface
      action    = interaction.requested_action

      # In #respond_for, error logging is handled. Since we generate a UUID
      # up front for errors (since a UUID is returned), we must not log under
      # that UUID twice. So in auto-log, only log success cases. Leave the
      # last-bastion-of-response that is #respond_for to deal with the rest.
      #
      return if ( context.response.halt_processing? )

      # Data as per Hoodoo::Services::Middleware::StructuredLogger.

      data = {
        :interaction_id => interaction.interaction_id,
        :session        => ( interaction.context.session || {} ).to_h
      }

      # Don't bother logging list responses - they could be huge - instead
      # log all list-related parameters from the inbound request.

      if context.response.body.is_a?( ::Array )
        attributes       = %i( list_offset list_limit list_sort_key list_sort_direction list_search_data list_filter_data embeds references )
        data[ :payload ] = {}

        attributes.each do | attribute |
          data[ attribute ] = context.request.send( attribute )
        end
      else
        data[ :payload ] = context.response.body
      end

      @@logger.report(
        :info,
        interface.resource,
        "middleware_#{ action }",
        data
      )
    end

    # Log a debug message. Pass optional extra arguments which will be used as
    # strings that get appended to the log message.
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

      scheme         = interaction.rack_request.scheme         || 'unknown_scheme'
      host_with_port = interaction.rack_request.host_with_port || 'unknown_host'
      full_path      = interaction.rack_request.fullpath       || '/unknown_path'

      data = {
        :full_uri       => "#{ scheme }://#{ host_with_port }#{ full_path }",
        :interaction_id => interaction.interaction_id,
        :payload        => { 'args' => args }
      }

      data[ :session ] = interaction.context.session.to_h unless interaction.context.session.nil?

      @@logger.report(
        :debug,
        :Middleware,
        :log,
        data
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
    # +interface+::      The Interface subclass for this endpoint.
    # +implementation+:: The Implementation subclass instance for this
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

        host = nil
        port = nil

        if defined?( ::Rack ) && defined?( ::Rack::Server )
          servers = ObjectSpace.each_object( ::Rack::Server )

          if servers.count == 1
            server = servers.first
            host   = server.options[ :Host ]
            port   = server.options[ :Port ]
          end
        end

        host = @@recorded_host if host.nil? && defined?( @@recorded_host )
        port = @@recorded_port if port.nil? && defined?( @@recorded_port )

        # In a test environment, default to a fake host and port if
        # need be.

        if ( self.class.environment.test? )
          host ||= '127.0.0.1'
          port ||= '9292'
        end

        # Now attempt to contact the DRb server daemon. If it can't be
        # contacted, try to start it first, then connect.

        drb_uri = Hoodoo::Services::Middleware::ServiceRegistryDRbServer.uri()
        DRb.start_service

        begin
          @@drb_service = DRbObject.new_with_uri( drb_uri )
          @@drb_service.ping()

        rescue DRb::DRbConnError
          script_path = File.join( File.dirname( __FILE__ ), 'service_registry_drb_server_start.rb' )
          Process.detach( spawn( "bundle exec ruby '#{ script_path }'" ) )

          begin
            Timeout::timeout( 5 ) do
              loop do
                begin
                  @@drb_service = DRbObject.new_with_uri( drb_uri )
                  @@drb_service.ping()
                  break
                rescue DRb::DRbConnError
                  sleep 0.1
                end
              end
            end

          rescue Timeout::Error
            raise "Middleware timed out while waiting for DRb service registry to start"

          end
        end

        # Announce our local services if we managed to find the host and port,
        # but no point otherwise; the values could be anything. In a 'guard'
        # based envrionment, first-run determines host and port but subsequent
        # runs do not - yet it stays the same, so it works out OK there.
        #
        unless host.nil? || port.nil?
          services.each do | service |
            interface = service[ :interface ]

            next if @@drb_service.find(
              interface.resource,
              interface.version
            )

            @@drb_service.add(
              interface.resource,
              interface.version,
              "http://#{ host }:#{ port }#{ service[ :path ] }"
            )
          end
        end
      end
    end

    # Load a session from Memcached on the basis of a session ID header
    # in the current interaction's Rack request data.
    #
    # On exit, the interaction context may have been updated. Be sure to
    # check +interaction.context.response.halt_processing?+ to see if
    # processing should abort and return immediately.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    def load_session_into( interaction )

      session    = nil
      session_id = interaction.rack_request.env[ 'HTTP_X_SESSION_ID' ]

      unless session_id.nil?
        session = Hoodoo::Services::Session.new(
          :memcached_host => self.class.memcached_host(),
          :session_id     => session_id
        )

        result = session.load_from_memcached!( session_id )
        session = nil if result != true
      end

      if self.class.environment.test? && session.nil?
        session = self.class.test_session()
      end

      # If there's no session and no local interfaces have any public
      # methods (everything is protected) then bail out early, as the
      # request can't possibly succeed.

      if session.nil? && interfaces_have_public_methods? == false
        return interaction.context.response.add_error( 'platform.invalid_session' )
      end

      # Update the interaction's context with the new session. Since
      # the context data is exposed to service implementations, the
      # session reference is read-only; don't break that protection;
      # instead build and use a replacement context.

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
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Parts of this may
    #                 be updated on exit.
    #
    def preprocess( interaction )


      # =======================================================================
      # Additions here may require corresponding additions to the
      # inter-resource local call code.
      # =======================================================================


      deal_with_content_type_header( interaction )
      deal_with_language_header( interaction )
      set_common_response_headers( interaction )

      # (SMH, Rack...)

      env     = interaction.rack_request.env
      headers = env.select do | key, value |
        key.to_s.match( /^HTTP_/ )
      end

      headers[ 'CONTENT_TYPE'   ] = env[ 'CONTENT_TYPE'   ]
      headers[ 'CONTENT_LENGTH' ] = env[ 'CONTENT_LENGTH' ]

      # Simplisitic CORS preflight handler. We might exit early here.
      #
      # http://www.html5rocks.com/en/tutorials/cors/
      # http://www.html5rocks.com/static/images/cors_server_flowchart.png
      #
      origin = headers[ 'HTTP_ORIGIN' ]

      unless ( origin.nil? )
        ok = false

        if interaction.rack_request.request_method == 'OPTIONS'
          requested_method  = headers[ 'HTTP_ACCESS_CONTROL_REQUEST_METHOD' ]
          requested_headers = headers[ 'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' ]
          allowed           = Set.new( %w( GET POST PATCH DELETE ) )

          if allowed.include?( requested_method ) && ( requested_headers.nil? || requested_headers.strip.empty? )
            set_cors_preflight_response_headers( interaction, origin )
            interaction.context.response.set_resources( [] )

            return respond_for( interaction )
          end
        else
          set_cors_normal_response_headers( interaction, origin )
        end
      end

      # If we reach here - it's a normal request, not preflight.

      load_session_into( interaction )

      # This is far too much work just to log the full details of the inbound
      # request, but Rack makes it ridiculously hard to extract the original
      # URI, request headers and body. We can't just log all of "env" as it
      # contains complex objects which break for-queue serialization.

      env  = interaction.rack_request.env
      body = interaction.rack_request.body.read( MAXIMUM_LOGGED_PAYLOAD_SIZE )
             interaction.rack_request.body.rewind()

      data = {
        :interaction_id => interaction.interaction_id,
        :payload        => {
          :method  => env[ 'REQUEST_METHOD', ],
          :scheme  => env[ 'rack.url_scheme' ],
          :host    => env[ 'SERVER_NAME'     ],
          :post    => env[ 'SERVER_PORT'     ],
          :script  => env[ 'SCRIPT_NAME'     ],
          :path    => env[ 'PATH_INFO'       ],
          :query   => env[ 'QUERY_STRING'    ],
          :headers => headers,
          :body    => body
        }
      }

      data[ :session ] = interaction.context.session.to_h unless interaction.context.session.nil?

      @@logger.report(
        :info,
        :Middleware,
        :inbound,
        data
      )

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

      uri_path = CGI.unescape( interaction.rack_request.path() )

      selected_path_data = nil
      selected_services  = @@services.select do | service_data |
        path_data = process_uri_path( uri_path, service_data[ :regexp ] )

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
        raise "Multiple service endpoint matches - internal server configuration fault"
      else
        selected_service = selected_services[ 0 ]
      end

      uri_path_components, uri_path_extension = selected_path_data
      interface                               = selected_service[ :interface      ]
      implementation                          = selected_service[ :implementation ]

      interaction.target_interface                  = interface
      interaction.target_resource_for_error_reports = interface.resource
      interaction.target_implementation             = implementation

      update_response_for( interaction.context.response, interface )

      # Check for a supported, session-accessible action.

      http_method                  = interaction.rack_request.request_method
      action                       = determine_action( http_method, uri_path_components.empty? )
      interaction.requested_action = action
      authorisation                = determine_authorisation( interaction )

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

      body = interaction.rack_request.body.read( MAXIMUM_PAYLOAD_SIZE )

      unless ( body.nil? || body.is_a?( ::String ) ) && interaction.rack_request.body.read( MAXIMUM_PAYLOAD_SIZE ).nil?
        return response.add_error( 'platform.malformed',
                                   'message' => 'Body data exceeds configured maximum size for platform' )
      end

      debug_log( interaction, 'Raw body data read successfully', body )

      if action == :create || action == :update
        parse_body_string_into( interaction, body )

        if response.halt_processing?
          return
        else
          validate_body_data_for( interaction )
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

      interface      = interaction.target_interface
      implementation = interaction.target_implementation
      action         = interaction.requested_action
      context        = interaction.context

      # Benchmark the "inner" dispatch call

      dispatch_time = Benchmark.realtime do

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

        if context.response.halt_processing?
          interaction.target_resource_for_error_reports = interface.resource
        end

        auto_log( interaction )

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
      # Hoodoo::Data::Resources collection.
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
      content_type      = interaction.rack_request.media_type
      content_encoding  = interaction.rack_request.content_charset

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
    # a list, we only take the first item; if there is a qvalue, we strip it
    # leaving just the language part, e.g. "en-gb".
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. Updated on exit.
    #
    def deal_with_language_header( interaction )
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

    # Preprocessing stage that sets up common headers required in any response.
    # May vary according to inbound content type requested. If processing was
    # aborted early (e.g. missing inbound Content-Type) we may fall to defaults.
    #
    # (At the time of writing, platform documentations say we're JSON only - but
    # there's an strong chance of e.g. XML representation being demanded later).
    #
    # +response+:: Hoodoo::Services::Response instance to update.
    #
    def set_common_response_headers( interaction )
      interaction.context.response.add_header( 'X-Interaction-ID', interaction.interaction_id )
      interaction.context.response.add_header( 'Content-Type', "#{ interaction.requested_content_type || 'application/json' }; charset=#{ interaction.requested_content_encoding || 'utf-8' }" )
    end

    # Preprocessing stage that sets up CORS response headers in response to a
    # normal (or preflight) CORS response.
    #
    # http://www.html5rocks.com/en/tutorials/cors/
    # http://www.html5rocks.com/static/images/cors_server_flowchart.png
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
    # http://www.html5rocks.com/en/tutorials/cors/
    # http://www.html5rocks.com/static/images/cors_server_flowchart.png
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    # +origin+::      Value of inbound request's "Origin" HTTP header.
    #
    def set_cors_preflight_response_headers( interaction, origin )

      set_cors_normal_response_headers( interaction, origin )

      # We don't try and figure out a target resource interface and give back
      # just the verbs it supports in preflight; too much trouble; just list
      # all *possible* supported methods.

      interaction.context.response.add_header(
        'Access-Control-Allow-Methods',
        'GET, POST, PATCH, DELETE'
      )

      # Only allow X-Session-ID inbound. Don't let any of the custom headers
      # be exposed to JavaScript (no "Access-Control-Expose-Headers" is set).

      interaction.context.response.add_header(
        'Access-Control-Allow-Headers',
        'X-Session-ID'
      )

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
    # information if successul. The interaction's response data will be
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
      query_hash = Hash[ query_data ]

      str                       = query_hash[ 'search' ]
      query_hash[ 'search' ]    = Hash[ URI.decode_www_form( str ) ] unless str.nil?

      str                       = query_hash[ 'filter' ]
      query_hash[ 'filter' ]    = Hash[ URI.decode_www_form( str ) ] unless str.nil?

      str                       = query_hash[ '_embed' ]
      query_hash[ '_embed']     = str.split( ',' ) unless str.nil?

      str                       = query_hash[ '_reference' ]
      query_hash[ '_reference'] = str.split( ',' ) unless str.nil?

      return process_query_hash( interaction, query_hash )
    end

    # Process a hash of URI-decoded form data in the same way as
    # #process_query_string (and used as a back-end for that). Nested search
    # and filter strings should be decoded as nested hashes. Nested _embed and
    # _reference lists should be stored as arrays. Keys and values must be
    # Strings.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction.
    #
    # +query_hash+::  Hash of data derived from query string - see
    #                 #process_query_string.
    #
    # The interaction's request data will be updated with list parameter
    # information if successul. The interaction's response data will be
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
      malformed = unrecognised_query_keys unless unrecognised_query_keys.empty?

      unless malformed
        if query_hash.has_key?( 'limit' )
          limit     = Hoodoo::Utilities::to_integer?( query_hash[ 'limit' ] )
          malformed = :limit if limit.nil?
        else
          limit = interface.to_list.limit.to_i
        end
      end

      unless malformed
        if query_hash.has_key?( 'offset' )
          offset    = Hoodoo::Utilities::to_integer?( query_hash[ 'offset' ] )
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

        unrecognised_search_keys = search.keys - interface.to_list.search
        malformed = "search: #{ unrecognised_search_keys.join(', ') }" unless unrecognised_search_keys.empty?
      end

      unless malformed
        filter = query_hash[ 'filter' ] || {}

        unrecognised_filter_keys = filter.keys - interface.to_list.filter
        malformed = "filter: #{ unrecognised_filter_keys.join(', ') }" unless unrecognised_filter_keys.empty?
      end

      unless malformed
        embeds = query_hash[ '_embed' ] || []

        unrecognised_embeds = embeds - interface.embeds
        malformed = "_embed: #{ unrecognised_embeds.join(', ') }" unless unrecognised_embeds.empty?
      end

      unless malformed
        references = query_hash[ '_reference' ] || []

        unrecognised_references = references - interface.embeds # (sic.)
        malformed = "_reference: #{ unrecognised_references.join(', ') }" unless unrecognised_references.empty?
      end

      return response.add_error(
        'platform.malformed',
        'message' => "One or more malformed or invalid query string parameters",
        'reference' => { :including => malformed }
      ) if malformed

      request.list.offset         = offset
      request.list.limit          = limit
      request.list.sort_key       = sort_key
      request.list.sort_direction = direction
      request.list.search_data    = search
      request.list.filter_data    = filter
      request.embeds              = embeds
      request.references          = references
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

            # We're aiming for Ruby 2.1 or later, but might end up on 1.9.
            #
            # https://www.ruby-lang.org/en/news/2013/02/22/json-dos-cve-2013-0269/
            #
            payload_hash = JSON.parse( body, :create_additions => false )

        end

      rescue => e
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

      unless ( verification_object.nil? )

        # 'false' => validate as type-only, not a resource (no ID, kind etc.)
        #
        result = verification_object.validate( body, false )

        if result.has_errors?
          response.errors.merge!( result )
        end
      end
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

  protected # :nodoc: all

    # Is the given resource available as a local endpoint in this service
    # application?
    #
    # +resource+:: Resource name of interest, e.g. +:Purchase+. String or
    #              symbol.
    #
    # +version+::  Version of interface required as an Integer. Optional -
    #              default is 1.
    #
    # Returns an @@services entry (see implementation of #initialize) if local,
    # else +nil+.
    #
    def local_service_for( resource, version = 1 )
      resource = resource.to_sym
      version  = version.to_i

      @@services.find do | entry |
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
    # Returns:
    #
    # * +nil+ if the endpoint is not found.
    #
    # * URI as a string if an endpoint is found and we are _not_ running on an
    #   AMQP/Alchemy based architecture (see ::on_queue?).
    #
    # * If an endpoint is found and we _are_ running on an AMQP/Alchemy based
    #   architecture (see ::on_queue?), this is a Hash with keys +:queue+
    #   (value is the AMQP queue name) and +path+ (the equivalent URI path that
    #   would be used, were this an HTTP request).
    #
    def remote_service_for( resource, version = 1 )

      if self.class.on_queue?

        v = "/v#{ version }/"

        # Static mapping until service discovery is sorted. Yes, this Hash gets
        # computed at run-time for every call. It's a temporary stopgap.
        #
        return {

          'Health'      => { :queue => 'service.utility',   :path => v + 'health'       },
          'Version'     => { :queue => 'service.utility',   :path => v + 'version'      },

          'Log'         => { :queue => 'service.logging',   :path => v + 'logs'         },
          'Errors'      => { :queue => 'service.logging',   :path => v + 'errors'       },
          'Statistic'   => { :queue => 'service.logging',   :path => v + 'statistics'   },

          'Account'     => { :queue => 'service.member',    :path => v + 'accounts'     },
          'Member'      => { :queue => 'service.member',    :path => v + 'members'      },
          'Membership'  => { :queue => 'service.member',    :path => v + 'memberships'  },
          'Token'       => { :queue => 'service.member',    :path => v + 'tokens'       },

          'Participant' => { :queue => 'service.programme', :path => v + 'participants' },
          'Outlet'      => { :queue => 'service.programme', :path => v + 'outlets'      },
          'Involvement' => { :queue => 'service.programme', :path => v + 'involvements' },
          'Programme'   => { :queue => 'service.programme', :path => v + 'programmes'   },

          'Balance'     => { :queue => 'service.financial', :path => v + 'balances'     },
          'Currency'    => { :queue => 'service.financial', :path => v + 'currencies'   },
          'Voucher'     => { :queue => 'service.financial', :path => v + 'vouchers'     },
          'Calculation' => { :queue => 'service.financial', :path => v + 'calculations' },
          'Transaction' => { :queue => 'service.financial', :path => v + 'transactions' },

          'Purchase'    => { :queue => 'service.purchase',  :path => v + 'purchases'    },

        }[ resource.to_s ]

      else

        return begin
          @@drb_service.find( resource, version )
        rescue
          nil
        end

      end
    end

    # Perform an inter-resource call. This shouldn't be called directly; call
    # via the Hoodoo::Services::Middleware::Endpoint subclass specialised
    # methods instead, which makes sure it sets up the required parameters in
    # correct combinations. Undefined results will arise for incorrect calls.
    #
    # +options+:: Options hash with keys and required values described below.
    #
    # Options are as follows - keys must be Symbols:
    #
    # +source_interaction+:: The Hoodoo::Services::Middleware::Interaction
    #                        instance that was created to handle the request
    #                        which led to a resource implementation being
    #                        called, that implementation now calling back
    #                        here to make an inter-resource call.
    #
    # +local+::              A +@@services+ entry (see implementation of
    #                        #initialize) describing the service to call if
    #                        local, else +nil+ or absent for remote calls.
    #
    # +remote+::             A return value of #remote_service_for describing
    #                        the location of a service for remote calls, else
    #                        +nil+ or absent for local calls.
    #
    # +resource+::           Resource name, String or Symbol, e.g. "Product".
    #
    # +version+::            Endpoint API version, Integer, e.g. 2.
    #
    # +http_method+::        HTTP method, String, e.g. "+GET+", "+DELETE+".
    #
    # +ident+::              ID, UUID etc; first (and only) path component.
    #
    # +query_hash+::         Converted to query string.
    #
    # +body_hash+::          Converted to body data.
    #
    # Parameters should be nil where the value would not be allowed given the
    # HTTP method. HTTP methods must map to understood actions.
    #
    # A Hoodoo::Services::Middleware::Endpoint::AugmentedArray or
    # Hoodoo::Services::Middleware::Endpoint::AugmentedHash is returned
    # from these methods; @response or the wider processing context
    # is not automatically modified. Callers MUST use the methods provided by
    # Hoodoo::Services::Middleware::Endpoint::AugmentedBase to detect
    # and handle error conditions, unless for some reason they wish to ignore
    # resource-to-resource call errors.
    #
    def inter_resource( options )

      interaction = options[ :source_interaction ]

      if interaction.nil?
        raise 'Hoodoo::Services::Middleware#inter_resource: Serious internal error - no source interaction data was provided'
      end

      remote = options[ :local ].nil?

      # Don't use string composition here; profiling shows it is slow and
      # this is only for debugging anyway.

      debug_str = if remote
        'Remote inter-resource call'
      else
        'Local inter-resource call'
      end

      debug_log( interaction, debug_str, 'requested', options )

      if ( remote )
        result = inter_resource_remote( options )
      else
        result = inter_resource_local( options )
      end

      if result.platform_errors.has_errors?
        debug_log( interaction, debug_str, 'halted processing', result.platform_errors )
      else
        debug_log( interaction, debug_str, 'succeeded', result )
      end

      return result
    end

    # Make a remote (HTTP) inter-resource call. Slow.
    #
    # +options+:: See #inter_resource.
    #
    # Returns:: See #inter_resource.
    #
    def inter_resource_remote( options )
      source_interaction = options[ :source_interaction ]
      remote_info        = options[ :remote             ]
      http_method        = options[ :http_method        ]
      ident              = options[ :ident              ]
      body_hash          = options[ :body_hash          ]
      query_hash         = options[ :query_hash         ]

      on_queue = self.class.on_queue?

      # Add a 404 error to the response (via a Proc for internal reuse).

      add_404 = Proc.new {
        hash = Hoodoo::Services::Middleware::Endpoint::AugmentedHash.new
        hash.platform_errors.add_error(
          'platform.not_found',
          'reference' => { :entity_name => "v#{ options[ :version ] } of #{ options[ :resource ] } interface endpoint" }
        )
        hash
      }

      # No endpoint found? Yikes!

      if ( remote_info.nil? )
        return add_404.call()

      elsif on_queue
        alchemy_options = {
          :host => source_interaction.rack_request.host,
          :port => source_interaction.rack_request.port
        }
        remote_info[:path] += "/#{ URI::escape( ident ) }" unless ident.nil?
      else
        remote_uri  = remote_info.dup # Duplicate => avoid accidental modify-"remote_info"-by-reference via "<<" below
        remote_uri << "/#{ URI::escape( ident ) }" unless ident.nil?
      end

      # When a source implementation calls a target implementation, we
      # look at the source implementation to see if it grants any extra
      # permissions for downstream resources it wants. All of that is
      # a "dialogue" that we have with the requesting, source resource
      # based on the action it is handling when it decides to make an
      # inter-resource call and the code control flow ends up here.

      session = augment_session_with_permissions_for_action( source_interaction )

      if session == false
        hash = Hoodoo::Services::Middleware::Endpoint::AugmentedHash.new
        hash.platform_errors.add_error( 'platform.invalid_session' )
        return hash
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
        if on_queue
          alchemy_options[ :query ] = query_hash
        else
          remote_uri << '?' << URI.encode_www_form( query_hash )
        end
      end

      body_data = body_hash.nil? ? '' : body_hash.to_json
      headers   = {
        'Content-Type'     => 'application/json; charset=utf-8',
        'Content-Language' => source_interaction.context.request.locale,
        'X-Interaction-ID' => source_interaction.interaction_id
      }

      headers[ 'X-Session-ID' ] = session.session_id unless session.nil?

      # Use HTTP or Alchemy for the actual communications.

      if on_queue

        # Call via Alchemy.

        unless defined?( @@alchemy ) && @@alchemy.nil? == false
          raise 'Inter-resource call requested on queue, but no Alchemy endpoint was sent in the Rack environment'
        end

        alchemy_options[ :body       ] = body_data
        alchemy_options[ :headers    ] = headers
        alchemy_options[ :session_id ] = session.session_id unless session.nil?

        response = @@alchemy.http_request(
          remote_info[ :queue ],
          http_method,
          remote_info[ :path ],
          alchemy_options
        )

      else

        # Drive Net::HTTP directly.

        remote_uri = URI.parse( remote_uri )
        http       = Net::HTTP.new( remote_uri.host, remote_uri.port )

        if remote_uri.scheme == "https"
          http.use_ssl = true
          # TODO: This is not so cool but want something going.
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

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

      end

      # If we get this far the interim session isn't needed. We might have
      # exited early due to errors above and left this behind, but that's not
      # the end of the world - it'll expire out of Memcached eventually.

      if session &&
         source_interaction.context &&
         source_interaction.context.session &&
         session.session_id != source_interaction.context.session.session_id

        # Ignore errors, there's nothing much we can do about them and in
        # the worst case we just have to wait for this to expire naturally.

        session.delete_from_memcached()
      end

      # Parse the response (assumed valid JSON else #for_rack would have failed
      # when the originating response object was turned into the Rack response).

      parsed = JSON.parse(
        response.body,
        :object_class => Hoodoo::Services::Middleware::Endpoint::AugmentedHash,
        :array_class  => Hoodoo::Services::Middleware::Endpoint::AugmentedArray
      )

      # Just in case someone changes JSON parsers under us and the replacement
      # doesn't support the options used above...

      unless parsed.is_a?( Hoodoo::Services::Middleware::Endpoint::AugmentedHash )
        raise "Hoodoo::Services::Middleware: Incompatible JSON implementation in use which doesn't understand 'object_class' or 'array_class' options"
      end

      # If the parsed data wrapped an array, extract just the array part, else
      # the hash part.

      if ( parsed[ '_data' ].is_a?( ::Array ) )
        size   = parsed[ '_dataset_size' ]
        parsed = parsed[ '_data'         ]
        parsed.dataset_size = size

      elsif ( parsed[ 'kind' ] == 'Errors' )

        # This isn't an array, it's an AugmentedHash describing errors. Turn
        # this into a formal errors collection.
        if on_queue
          code = response.status_code
        else
          code = response.code
        end
        errors_from_other_resource = Hoodoo::Errors.new()
        parsed[ 'errors' ].each do | error |
          errors_from_other_resource.add_precompiled_error(
            error[ 'code'      ],
            error[ 'message'   ],
            error[ 'reference' ],
            code
          )
        end

        parsed.set_platform_errors(
          translate_errors_from_other_resource( errors_from_other_resource )
        )
      end

      return parsed
    end

    # Make a local (non-HTTP local Ruby method call) inter-resource call. Fast.
    #
    # +options+:: See #inter_resource.
    #
    # Returns:: See #inter_resource.
    #
    def inter_resource_local( options )
      source_interaction = options[ :source_interaction ]
      service            = options[ :local              ]
      http_method        = options[ :http_method        ]
      ident              = options[ :ident              ]
      body_hash          = options[ :body_hash          ]
      query_hash         = options[ :query_hash         ]

      interface          = service[ :interface      ]
      actions            = service[ :actions        ]
      implementation     = service[ :implementation ]

      # We must construct a call context for the local service. This means
      # a local request object which we fill in with data just as if we'd
      # parsed an inbound HTTP request and a response object that contains
      # the usual default data.

      env = {
        'HTTP_X_INTERACTION_ID' => source_interaction.interaction_id
      }

      # Need to possibly augment the caller's session - same rationale
      # as #local_service_remote, so see that for details.

      session = augment_session_with_permissions_for_action( source_interaction )

      if session == false
        hash = Hoodoo::Services::Middleware::Endpoint::AugmentedHash.new
        hash.platform_errors.add_error( 'platform.invalid_session' )
        return hash
      end

      local_interaction = Hoodoo::Services::Middleware::Interaction.new(
        {},
        self,
        session
      )

      local_interaction.target_interface                  = interface
      local_interaction.target_implementation             = implementation
      local_interaction.target_resource_for_error_reports = interface.resource
      local_interaction.requested_content_type            = source_interaction.requested_content_type
      local_interaction.requested_content_encoding        = source_interaction.requested_content_encoding

      # For convenience...

      local_request  = local_interaction.context.request
      local_response = local_interaction.context.response

      set_common_response_headers( local_interaction )
      update_response_for( local_response, interface )

      # Add errors from the local service response into an augmented hash
      # for responding early (via a Proc for internal reuse later).

      add_local_errors = Proc.new {
        hash = Hoodoo::Services::Middleware::Endpoint::AugmentedHash.new
        hash.platform_errors.merge!( local_response.errors )
        hash
      }

      # Figure out initial action / authorisation results for this request.
      # We may still have to construct a context and ask the service after.

      upc  = []
      upc << ident unless ident.nil? || ident.empty?

      action                             = determine_action( http_method, upc.empty? )
      local_interaction.requested_action = action
      authorisation                      = determine_authorisation( local_interaction )

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
      # the end of the world - it'll expire out of Memcached eventually.

      if session &&
         source_interaction.context &&
         source_interaction.context.session &&
         session.session_id != source_interaction.context.session.session_id

        # Ignore errors, there's nothing much we can do about them and in
        # the worst case we just have to wait for this to expire naturally.

        session.delete_from_memcached()
      end

      # Extract the returned data and "rephrase" it as an augmented
      # array or hash carrying error data if necessary.

      data = local_response.body

      if data.is_a? Array
        data              = Hoodoo::Services::Middleware::Endpoint::AugmentedArray.new( data )
        data.dataset_size = local_response.dataset_size
      else
        data = Hoodoo::Services::Middleware::Endpoint::AugmentedHash[ data ]
      end

      data.set_platform_errors(
        translate_errors_from_other_resource( local_response.errors )
      )

      return data
    end

    # Take the current session (if any) and create an interim augmented
    # session for an inter-resource call which includes any additional
    # parameters that the calling interface says it needs for the currently
    # handled action.
    #
    # Through calling this method, the middleware implements the access
    # permission functionality described by
    # Hoodoo::Services::Interface#additional_permissions_for.
    #
    # +interaction+:: Hoodoo::Services::Middleware::Interaction instance
    #                 describing the current interaction. This is for the
    #                 request that a resource implementation *is handling*
    #                 at the point it wants to make an inter-resource call
    #                 - it is *not* data related to the *target* of that
    #                 call.
    #
    # Returns:
    #
    # * +nil+ if given +nil+ as an input session.
    #
    # * Hoodoo::Services::Session instance if everything works OK; this
    #   may be the same as, or different from, the input session depending
    #   on whether or not there were any permissions that needed adding.
    #
    # * +false+ if the session can't be saved due to a mismatched caller
    #   version - the session must have become invalid _during_ handling.
    #
    # If the augmented session cannot be saved due to a Memcached problem,
    # an exception is raised and the generic handler will turn this into a
    # 500 response for the caller. At this time, we really can't do much
    # better than that since failure to save the augmented session means
    # the inter-resource call cannot proceed; it's an internal fault.
    #
    def augment_session_with_permissions_for_action( interaction )

      # Set up some convenience variables

      session   = interaction.context.session
      interface = interaction.target_interface
      action    = interaction.requested_action

      # If there is no session, the caller can only have reached here via
      # a public action. We don't let public actions call protected actions.
      # Just return "nil" back again and let the usual permissions checking
      # code then refuse the request.

      return nil if session.nil?

      # If there are no additional permissions for this action, just return
      # the current session back again.

      action                 = action.to_s()
      additional_permissions = ( interface.additional_permissions() || {} )[ action ]

      return session if additional_permissions.nil?

      # Otherwise, duplicate the session and its permissions (or generate
      # defaults) and merge the additional permissions.

      local_session     = session.dup()
      local_permissions = session.permissions ? session.permissions.dup() : Hoodoo::Services::Permissions.new

      local_permissions.merge!( additional_permissions.to_h() )

      # Make sure the new session has its own ID and set the updated
      # permissions. Then try to save it and return the result.

      local_session.session_id  = Hoodoo::UUID.generate()
      local_session.permissions = local_permissions

      case local_session.save_to_memcached()
        when true
          return local_session

        when false
          # Caller version mismatch; original session is now outdated and invalid
          return false

        else # Couldn't save it
          raise "Unable to create interim session for inter-resource call from #{ interface.resource } / #{ action }"
      end
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
    def translate_errors_from_other_resource( errors )
      # TODO - lots of testing; e.g. c.f. nested basket items accumulating
      # a bunch of 404s for products which weren't found via a complex path.
      return errors
    end

    # The following must appear at the end of this class definition.

    set_up_basic_logging()

  end    # 'class Middleware'
end; end # 'module Hoodoo; module Services'
