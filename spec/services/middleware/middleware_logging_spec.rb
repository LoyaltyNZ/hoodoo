# service_middleware_spec.rb is too large. This file covers logging
# extentions around StructuredLogger.

require 'spec_helper'

class TestLogImplementation < Hoodoo::Services::Implementation
  def show( context )
    context.response.body = { 'show' => 'the thing', 'the_thing' => context.request.ident }
  end

  def create( context )
    context.response.set_resource( { 'log' => 'create' } )
  end

  def update( context )
    context.response.set_resource( { 'log' => 'update' } )
  end
end

class TestLogInterface < Hoodoo::Services::Interface
  interface :TestLog do
    endpoint :test_log, TestLogImplementation
    actions :show, :create, :update

    secure_log_for :create => :request,
                   :update => :response
  end
end

class TestLogService < Hoodoo::Services::Service
  comprised_of TestLogInterface
end

class TestLogInterfaceB < Hoodoo::Services::Interface
  interface :TestLogB do
    version 2
    endpoint :test_log_b, TestLogImplementation
    actions :show, :create, :update

    secure_log_for :create => :both
  end
end

class TestLogService < Hoodoo::Services::Service
  comprised_of TestLogInterfaceB
end

# Force the middleware logging mode to that passed as a string in 'test_env'.
# You must have an 'after' block which restores normal test logging if you
# use this, else other tests may subsequently fail. Returns the log writer
# instances now in use as an array (Hoodoo::Logger#instances).
#
def force_logging_to( test_env )
  Hoodoo::Services::Middleware.class_variable_set( '@@environment', Hoodoo::StringInquirer.new( test_env ) )
  Hoodoo::Services::Middleware.class_variable_set( '@@external_logger', false )
  Hoodoo::Services::Middleware.send( :set_up_basic_logging )
  Hoodoo::Services::Middleware.send( :add_file_logging, File.join( File.dirname( __FILE__), '..', '..', 'log' ) )
  return Hoodoo::Services::Middleware.logger.instances
end

describe Hoodoo::Services::Middleware do

  before :each do
    @old_env = Hoodoo::Services::Middleware::class_variable_get( '@@environment' )
    @old_logger = Hoodoo::Services::Middleware::logger
  end

  after :each do
    Hoodoo::Services::Middleware::logger.wait()
    force_logging_to( 'test' )
    Hoodoo::Services::Middleware.class_variable_set( '@@environment', @old_env )
    Hoodoo::Services::Middleware.class_variable_set( '@@logger', @old_logger )
    begin
      Hoodoo::Services::Middleware.remove_class_variable( '@@alchemy' )
    rescue
    end
  end

  context 'custom loggers' do
    before :each do
      @custom = Hoodoo::Logger.new
      Hoodoo::Services::Middleware.set_logger( @custom )
    end

    it 'sets a custom logger' do
      expect( Hoodoo::Services::Middleware.logger ).to eq( @custom )
    end

    it 'complains about bad custom loggers' do
      expect {
        Hoodoo::Services::Middleware.set_logger( Object )
      }.to raise_error( RuntimeError, "Hoodoo::Communicators::set_logger must be called with an instance of Hoodoo::Logger only" )
    end

    it 'does not add other writers' do
      Hoodoo::Services::Middleware.set_log_folder( '/foo' )
      Hoodoo::Services::Middleware.set_log_folder( '/bar' )
      expect( @custom.instances ).to be_empty
    end
  end

  context 'off queue' do
    before :each do
      @old_queue = ENV[ 'AMQ_URI' ]
      ENV[ 'AMQ_URI' ] = nil

      @cvar = false
      if Hoodoo::Services::Middleware.class_variable_defined?( '@@alchemy' )
        @cvar = true
        @cvar_val = Hoodoo::Services::Middleware.class_variable_get( '@@alchemy' )
      end
    end

    after :each do
      ENV[ 'AMQ_URI' ] = @old_queue

      if Hoodoo::Services::Middleware.class_variable_defined?( '@@alchemy' )
        if @cvar == true
          Hoodoo::Services::Middleware.class_variable_set( '@@alchemy', @cvar_val )
        else
          Hoodoo::Services::Middleware.remove_class_variable( '@@alchemy' )
        end
      end
    end

    def app
      Rack::Builder.new do
        use Hoodoo::Services::Middleware
        run TestLogService.new
      end
    end

    it 'has the expected "test" mode loggers' do
      instances = force_logging_to( 'test' )

      expect( instances[ 0 ] ).to be_a( Hoodoo::Logger::FileWriter )
      expect( Hoodoo::Services::Middleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "development" mode loggers' do
      instances = force_logging_to( 'development' )

      expect( instances[ 0 ] ).to be_a( Hoodoo::Logger::StreamWriter )
      expect( instances[ 1 ] ).to be_a( Hoodoo::Logger::FileWriter )
      expect( Hoodoo::Services::Middleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "production" mode loggers' do
      instances = force_logging_to( 'production' )

      expect( instances[ 0 ] ).to be_a( Hoodoo::Logger::FileWriter )
      expect( Hoodoo::Services::Middleware.logger.level ).to eq( :info )
    end
  end

  context 'on queue' do
    before :each do
      @old_queue = ENV[ 'AMQ_URI' ]
      ENV[ 'AMQ_URI' ] = 'amqp://test:test@127.0.0.1'

      @cvar = false
      if Hoodoo::Services::Middleware.class_variable_defined?( '@@alchemy' )
        @cvar = true
        @cvar_val = Hoodoo::Services::Middleware.class_variable_get( '@@alchemy' )
      end
    end

    after :each do
      ENV[ 'AMQ_URI' ] = @old_queue

      if Hoodoo::Services::Middleware.class_variable_defined?( '@@alchemy' )
        if @cvar == true
          Hoodoo::Services::Middleware.class_variable_set( '@@alchemy', @cvar_val )
        else
          Hoodoo::Services::Middleware.remove_class_variable( '@@alchemy' )
        end
      end
    end

    class FakeAlchemy
      def initialize(app)
        @app = app
      end
      def call(env)
        env['alchemy.service'] = self
        @app.call(env)
      end
      def send_message(*args)
      end
    end

    def app
      Rack::Builder.new do
        use FakeAlchemy
        use Hoodoo::Services::Middleware
        run TestLogService.new
      end
    end

    # In these tests, the logger instance array isn't complete until at least
    # one call has gone through the middleware, providing an Alchemy endpoint
    # and allowing the on-queue logger to be added.

    it 'has the expected "test" mode loggers' do
      force_logging_to( 'test' )

      get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      instances = Hoodoo::Services::Middleware.logger.instances
      expect( instances[ 0 ] ).to be_a( Hoodoo::Logger::FileWriter )
      expect( Hoodoo::Services::Middleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "development" mode loggers' do
      force_logging_to( 'development' )

      expect_any_instance_of(FakeAlchemy).to receive(:send_message_to_service).at_least(:once)
      spec_helper_silence_stdout() do
        get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      end

      instances = Hoodoo::Services::Middleware.logger.instances
      expect( instances[ 0 ] ).to be_a( Hoodoo::Logger::StreamWriter )
      expect( instances[ 1 ] ).to be_a( Hoodoo::Services::Middleware::AMQPLogWriter )
      expect( Hoodoo::Services::Middleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "production" mode loggers' do
      force_logging_to( 'production' )

      expect_any_instance_of(FakeAlchemy).to receive(:send_message_to_service).at_least(:once)
      get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      instances = Hoodoo::Services::Middleware.logger.instances
      expect( instances[ 0 ] ).to be_a( Hoodoo::Services::Middleware::AMQPLogWriter )
      expect( Hoodoo::Services::Middleware.logger.level ).to eq( :info )
    end

    # When logging to Alchemy, the middleware should set an
    # "X-Error-Logged-Via-Alchemy" HTTP header. An Alchemy router/edge
    # splitter component can use this to avoid double-logging error data
    # if it implements a middleware-based approach to error reporting.
    #
    context '"X-Error-Logged-Via-Alchemy" HTTP header is set for' do
      before :each do
        force_logging_to( 'development' )
        expect_any_instance_of(FakeAlchemy).to receive(:send_message_to_service).at_least(:once)
      end

      it 'service errors' do
        expect_any_instance_of( TestLogImplementation ).to receive( :show ) do | instance, context |
          context.response.not_found( context.request.ident )
        end

        spec_helper_silence_stdout do
          get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        end

        expect( last_response.headers[ 'X-Error-Logged-Via-Alchemy' ] ).to eq( 'yes' )
        expect( last_response.status ).to eq( 404 )
      end

      it 'service exceptions' do
        expect_any_instance_of( TestLogImplementation ).to receive( :show ) do
          raise "boo!"
        end

        spec_helper_silence_stdout do
          get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        end

        expect( last_response.headers[ 'X-Error-Logged-Via-Alchemy' ] ).to eq( 'yes' )
        expect( last_response.status ).to eq( 500 )
      end

      context 'invalid' do
        before :each do
          @old_test_session = Hoodoo::Services::Middleware.test_session()
        end

        after :each do
          Hoodoo::Services::Middleware.set_test_session( @old_test_session )
        end

        it 'session errors' do
          Hoodoo::Services::Middleware.set_test_session( nil )

          spec_helper_silence_stdout do
            get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
          end

          expect( last_response.headers[ 'X-Error-Logged-Via-Alchemy' ] ).to eq( 'yes' )
          expect( last_response.status ).to eq( 401 )
        end

        it 'permission errors' do
          session             = @old_test_session.dup()
          session.permissions = Hoodoo::Services::Permissions.new # Default is 'deny all'

          Hoodoo::Services::Middleware.set_test_session( session )

          spec_helper_silence_stdout do
            get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
          end

          expect( last_response.headers[ 'X-Error-Logged-Via-Alchemy' ] ).to eq( 'yes' )
          expect( last_response.status ).to eq( 403 )
        end
      end

      # Middleware exceptions are not tested. There's no way to know the kind
      # of failure that might happen in the real-world and the point at which
      # the exception occurs in the processing chain may influence whether or
      # not the header gets set. We might end up with double logging from an
      # router/edge splitter in such cases, but that's acceptable for what
      # should be an extremely rare event.

    end
  end

  context 'secure logging' do
    class HashLogger < Hoodoo::Logger::FastWriter
      @@log_data = []

      def self.reset
        @@log_data = []
      end

      def self.log_data
        @@log_data
      end

      def report( log_level, component, code, data )
        @@log_data << { log_level: log_level, component: component, code: code, data: data }
      end
    end

    def get_data_for( action )
      inbound  = HashLogger.log_data().select { | x | x[ :code ] == :inbound }
      result   = HashLogger.log_data().select { | x | x[ :code ] == "middleware_#{ action }" }
      outbound = HashLogger.log_data().select { | x | x[ :code ] == :outbound }

      expect( inbound  ).to_not be_empty
      expect( result   ).to_not be_empty
      expect( outbound ).to_not be_empty

      return [ inbound, result, outbound ]
    end

    before :each do
      HashLogger.reset()
      logger = Hoodoo::Logger.new
      logger.add( HashLogger.new )
      Hoodoo::Services::Middleware.set_logger( logger )
    end

    def app
      Rack::Builder.new do
        use Hoodoo::Services::Middleware
        run TestLogService.new
      end
    end

    def check_common_entries( resource, version, action, *args )
      args.each do | entry |
        expect( entry ).to have_key( :log_level )
        expect( entry ).to have_key( :code      )
        expect( entry ).to have_key( :component )
        expect( entry ).to have_key( :data      )

        expect( entry[ :data ] ).to have_key( :interaction_id )
        expect( entry[ :data ] ).to have_key( :session        )
        expect( entry[ :data ] ).to have_key( :target         )

        expect( entry[ :data ][ :target ] ).to have_key( :resource )
        expect( entry[ :data ][ :target ] ).to have_key( :version  )
        expect( entry[ :data ][ :target ] ).to have_key( :action   )

        expect( entry[ :data ][ :target ][ :resource ] ).to eq( resource )
        expect( entry[ :data ][ :target ][ :version  ] ).to eq( version  )
        expect( entry[ :data ][ :target ][ :action   ] ).to eq( action   )
      end
    end

    # To test_log, 'create' says secure for 'request'
    #
    it 'does not log creation requests unexpectedly' do
      post '/v1/test_log', '{ "foo": "bar" }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      inbound, result, outbound = get_data_for( :create )
      check_common_entries( 'TestLog', 1, 'create', inbound.last, result.first, outbound.first )

      entry = inbound.last;   expect( entry[ :data ][ :payload ] ).to_not have_key( :body )
      entry = result.first;   expect( entry[ :data ]             ).to     have_key( :payload )
      entry = outbound.first; expect( entry[ :data ][ :payload ] ).to     have_key( :response_body )
    end

    # To test_log, 'update' says secure for 'request'
    #
    it 'does not log update responses unexpectedly' do
      patch '/v1/test_log/foo', '{ "foo": "bar" }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      inbound, result, outbound = get_data_for( :update )
      check_common_entries( 'TestLog', 1, 'update', inbound.last, result.first, outbound.first )

      entry = inbound.last;   expect( entry[ :data ][ :payload ] ).to     have_key( :body )
      entry = result.first;   expect( entry[ :data ]             ).to_not have_key( :payload )
      entry = outbound.first; expect( entry[ :data ][ :payload ] ).to_not have_key( :response_body )
    end

    # To test_log_b, 'create' says secure for 'both'.
    #
    it 'does not log requests or responses unexpectedly' do
      post '/v2/test_log_b', '{ "foo": "bar" }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      inbound, result, outbound = get_data_for( :create )
      check_common_entries( 'TestLogB', 2, 'create', inbound.last, result.first, outbound.first )

      entry = inbound.last;   expect( entry[ :data ][ :payload ] ).to_not have_key( :body )
      entry = result.first;   expect( entry[ :data ]             ).to_not have_key( :payload )
      entry = outbound.first; expect( entry[ :data ][ :payload ] ).to_not have_key( :response_body )
    end

    # To test_log_b, 'update' does not ask for security.
    #
    it 'does not log requests or responses unexpectedly' do
      patch '/v2/test_log_b/foo', '{ "foo": "bar" }', { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      inbound, result, outbound = get_data_for( :update )
      check_common_entries( 'TestLogB', 2, 'update', inbound.last, result.first, outbound.first )

      entry = inbound.last;   expect( entry[ :data ][ :payload ] ).to have_key( :body )
      entry = result.first;   expect( entry[ :data ]             ).to have_key( :payload )
      entry = outbound.first; expect( entry[ :data ][ :payload ] ).to have_key( :response_body )
    end
  end
end
