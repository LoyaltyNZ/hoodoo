# service_middleware_spec.rb is too large. This file covers logging
# extentions around StructuredLogger and AMQPLogMessage.

require 'spec_helper'

class TestLogServiceImplementation < Hoodoo::ServiceImplementation
  def show( context )
    context.response.body = { 'show' => 'the thing', 'the_thing' => context.request.ident }
  end
end

class TestLogServiceInterface < Hoodoo::ServiceInterface
  interface :TestLog do
    endpoint :test_log, TestLogServiceImplementation
    actions :show
  end
end

class TestLogServiceApplication < Hoodoo::ServiceApplication
  comprised_of TestLogServiceInterface
end

# Force the middleware logging mode to that passed as a string in 'test_env'.
# You must have an 'after' block which restores normal test logging if you
# use this, else other tests may subsequently fail. Returns the log writer
# instances now in use as an array (Hoodoo::Logger#instances).
#
def force_logging_to( test_env )
  Hoodoo::ServiceMiddleware.class_variable_set( '@@_env', Hoodoo::StringInquirer.new( test_env ) )
  Hoodoo::ServiceMiddleware.class_variable_set( '@@external_logger', false )
  Hoodoo::ServiceMiddleware.send( :set_up_basic_logging )
  Hoodoo::ServiceMiddleware.send( :add_file_logging, File.join( File.dirname( __FILE__), '..', '..', 'log' ) )
  return Hoodoo::ServiceMiddleware.logger.instances
end

describe Hoodoo::ServiceMiddleware do

  before :each do
    @old_env = Hoodoo::ServiceMiddleware::class_variable_get( '@@_env' )
    @old_logger = Hoodoo::ServiceMiddleware::logger
  end

  after :each do
    Hoodoo::ServiceMiddleware::logger.wait()
    force_logging_to( 'test' )
    Hoodoo::ServiceMiddleware.class_variable_set( '@@_env', @old_env )
    Hoodoo::ServiceMiddleware.class_variable_set( '@@logger', @old_logger )
    begin
      Hoodoo::ServiceMiddleware.remove_class_variable( '@@alchemy' )
    rescue
    end
  end

  context 'custom loggers' do
    before :each do
      @custom = Hoodoo::Logger.new
      Hoodoo::ServiceMiddleware.set_logger( @custom )
    end

    it 'sets a custom logger' do
      expect( Hoodoo::ServiceMiddleware.logger ).to eq( @custom )
    end

    it 'complains about bad custom loggers' do
      expect {
        Hoodoo::ServiceMiddleware.set_logger( Object )
      }.to raise_error( RuntimeError, "Hoodoo::Communicators::set_logger must be called with an instance of Hoodoo::Logger only" )
    end

    it 'does not add other writers' do
      Hoodoo::ServiceMiddleware.set_log_folder( '/foo' )
      Hoodoo::ServiceMiddleware.set_log_folder( '/bar' )
      expect( @custom.instances ).to be_empty
    end
  end

  context 'off queue' do
    before :each do
      @old_queue = ENV[ 'AMQ_ENDPOINT' ]
      ENV[ 'AMQ_ENDPOINT' ] = nil

      @cvar = false
      if Hoodoo::ServiceMiddleware.class_variable_defined?( '@@alchemy' )
        @cvar = true
        @cvar_val = Hoodoo::ServiceMiddleware.class_variable_get( '@@alchemy' )
      end
    end

    after :each do
      ENV[ 'AMQ_ENDPOINT' ] = @old_queue

      if Hoodoo::ServiceMiddleware.class_variable_defined?( '@@alchemy' )
        if @cvar == true
          Hoodoo::ServiceMiddleware.class_variable_set( '@@alchemy', @cvar_val )
        else
          Hoodoo::ServiceMiddleware.remove_class_variable( '@@alchemy' )
        end
      end
    end

    def app
      Rack::Builder.new do
        use Hoodoo::ServiceMiddleware
        run TestLogServiceApplication.new
      end
    end

    it 'has the expected "test" mode loggers' do
      instances = force_logging_to( 'test' )

      expect( instances[ 0 ] ).to be_a( Hoodoo::Logger::FileWriter )
      expect( Hoodoo::ServiceMiddleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "development" mode loggers' do
      instances = force_logging_to( 'development' )

      expect( instances[ 0 ] ).to be_a( Hoodoo::Logger::StreamWriter )
      expect( instances[ 1 ] ).to be_a( Hoodoo::Logger::FileWriter )
      expect( Hoodoo::ServiceMiddleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "production" mode loggers' do
      instances = force_logging_to( 'production' )

      expect( instances[ 0 ] ).to be_a( Hoodoo::Logger::FileWriter )
      expect( Hoodoo::ServiceMiddleware.logger.level ).to eq( :info )
    end
  end

  context 'on queue' do
    before :each do
      @old_queue = ENV[ 'AMQ_ENDPOINT' ]
      ENV[ 'AMQ_ENDPOINT' ] = 'amqp://test:test@127.0.0.1'

      @cvar = false
      if Hoodoo::ServiceMiddleware.class_variable_defined?( '@@alchemy' )
        @cvar = true
        @cvar_val = Hoodoo::ServiceMiddleware.class_variable_get( '@@alchemy' )
      end
    end

    after :each do
      ENV[ 'AMQ_ENDPOINT' ] = @old_queue

      if Hoodoo::ServiceMiddleware.class_variable_defined?( '@@alchemy' )
        if @cvar == true
          Hoodoo::ServiceMiddleware.class_variable_set( '@@alchemy', @cvar_val )
        else
          Hoodoo::ServiceMiddleware.remove_class_variable( '@@alchemy' )
        end
      end
    end

    class FakeAlchemy
      def initialize(app)
        @app = app
      end
      def call(env)
        env['rack.alchemy'] = self
        @app.call(env)
      end
      def send_message(*args)
      end
    end

    def app
      Rack::Builder.new do
        use FakeAlchemy
        use Hoodoo::ServiceMiddleware
        run TestLogServiceApplication.new
      end
    end

    # In these tests, the logger instance array isn't complete until at least
    # one call has gone through the middleware, providing an Alchemy endpoint
    # and allowing the on-queue logger to be added.

    it 'has the expected "test" mode loggers' do
      force_logging_to( 'test' )

      get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      instances = Hoodoo::ServiceMiddleware.logger.instances
      expect( instances[ 0 ] ).to be_a( Hoodoo::Logger::FileWriter )
      expect( Hoodoo::ServiceMiddleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "development" mode loggers' do
      force_logging_to( 'development' )

      expect_any_instance_of(FakeAlchemy).to receive(:send_message).at_least(:once)
      spec_helper_silence_stdout() do
        get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      end

      instances = Hoodoo::ServiceMiddleware.logger.instances
      expect( instances[ 0 ] ).to be_a( Hoodoo::Logger::StreamWriter )
      expect( instances[ 1 ] ).to be_a( Hoodoo::ServiceMiddleware::AMQPLogWriter )
      expect( Hoodoo::ServiceMiddleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "production" mode loggers' do
      force_logging_to( 'production' )

      expect_any_instance_of(FakeAlchemy).to receive(:send_message).at_least(:once)
      get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      instances = Hoodoo::ServiceMiddleware.logger.instances
      expect( instances[ 0 ] ).to be_a( Hoodoo::ServiceMiddleware::AMQPLogWriter )
      expect( Hoodoo::ServiceMiddleware.logger.level ).to eq( :info )
    end
  end
end
