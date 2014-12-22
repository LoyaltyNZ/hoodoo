# service_middleware_spec.rb is too large. This file covers logging
# extentions around StructuredLogger and AMQPLogMessage.

require 'spec_helper'

class TestLogServiceImplementation < ApiTools::ServiceImplementation
  def show( context )
    context.response.body = { 'show' => 'the thing', 'the_thing' => context.request.ident }
  end
end

class TestLogServiceInterface < ApiTools::ServiceInterface
  interface :TestLog do
    endpoint :test_log, TestLogServiceImplementation
    actions :show
  end
end

class TestLogServiceApplication < ApiTools::ServiceApplication
  comprised_of TestLogServiceInterface
end

# Force the middleware logging mode to that passed as a string in 'test_env'.
# You must have an 'after' block which restores normal test logging if you
# use this, else other tests may subsequently fail. Returns the log writer
# instances now in use as an array (ApiTools::Logger#instances).
#
def force_logging_to( test_env )
  ApiTools::ServiceMiddleware.class_variable_set( '@@_env', ApiTools::StringInquirer.new( test_env ) )
  ApiTools::ServiceMiddleware.class_variable_set( '@@external_logger', false )
  ApiTools::ServiceMiddleware.send( :set_up_basic_logging )
  ApiTools::ServiceMiddleware.send( :add_file_logging, File.join( File.dirname( __FILE__), '..', '..', 'log' ) )
  return ApiTools::ServiceMiddleware.logger.instances
end

describe ApiTools::ServiceMiddleware do

  before :each do
    @old_env = ApiTools::ServiceMiddleware::class_variable_get( '@@_env' )
    @old_logger = ApiTools::ServiceMiddleware::logger
  end

  after :each do
    ApiTools::ServiceMiddleware::logger.wait()
    force_logging_to( 'test' )
    ApiTools::ServiceMiddleware.class_variable_set( '@@_env', @old_env )
    ApiTools::ServiceMiddleware.class_variable_set( '@@logger', @old_logger )
    begin
      ApiTools::ServiceMiddleware.remove_class_variable( '@@alchemy' )
    rescue
    end
  end

  context 'custom loggers' do
    before :each do
      @custom = ApiTools::Logger.new
      ApiTools::ServiceMiddleware.set_logger( @custom )
    end

    it 'sets a custom logger' do
      expect( ApiTools::ServiceMiddleware.logger ).to eq( @custom )
    end

    it 'complains about bad custom loggers' do
      expect {
        ApiTools::ServiceMiddleware.set_logger( Object )
      }.to raise_error( RuntimeError, "ApiTools::Communicators::set_logger must be called with an instance of ApiTools::Logger only" )
    end

    it 'does not add other writers' do
      ApiTools::ServiceMiddleware.set_log_folder( '/foo' )
      ApiTools::ServiceMiddleware.set_log_folder( '/bar' )
      expect( @custom.instances ).to be_empty
    end
  end

  context 'off queue' do
    before :each do
      @old_queue = ENV.delete( 'AMQ_ENDPOINT' )
    end

    after :each do
      ENV[ 'AMQ_ENDPOINT' ] = @old_queue unless @old_queue.nil?
    end

    def app
      Rack::Builder.new do
        use ApiTools::ServiceMiddleware
        run TestLogServiceApplication.new
      end
    end

    it 'has the expected "test" mode loggers' do
      instances = force_logging_to( 'test' )

      expect( instances[ 0 ] ).to be_a( ApiTools::Logger::FileWriter )
      expect( ApiTools::ServiceMiddleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "development" mode loggers' do
      instances = force_logging_to( 'development' )

      expect( instances[ 0 ] ).to be_a( ApiTools::Logger::StreamWriter )
      expect( instances[ 1 ] ).to be_a( ApiTools::Logger::FileWriter )
      expect( ApiTools::ServiceMiddleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "production" mode loggers' do
      instances = force_logging_to( 'production' )

      expect( instances[ 0 ] ).to be_a( ApiTools::Logger::FileWriter )
      expect( ApiTools::ServiceMiddleware.logger.level ).to eq( :info )
    end
  end

  context 'on queue' do
    before :each do
      @old_queue = ENV.delete( 'AMQ_ENDPOINT' )
      ENV[ 'AMQ_ENDPOINT' ] = 'amqp://127.0.0.1:1234/'
    end

    after :each do
      if @old_queue.nil?
        ENV.delete( 'AMQ_ENDPOINT' )
      else
        ENV[ 'AMQ_ENDPOINT' ] = @old_queue
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
        use ApiTools::ServiceMiddleware
        run TestLogServiceApplication.new
      end
    end

    # In these tests, the logger instance array isn't complete until at least
    # one call has gone through the middleware, providing an Alchemy endpoint
    # and allowing the on-queue logger to be added.

    it 'has the expected "test" mode loggers' do
      force_logging_to( 'test' )

      get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      instances = ApiTools::ServiceMiddleware.logger.instances
      expect( instances[ 0 ] ).to be_a( ApiTools::Logger::FileWriter )
      expect( ApiTools::ServiceMiddleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "development" mode loggers' do
      force_logging_to( 'development' )

      expect_any_instance_of(FakeAlchemy).to receive(:send_message).at_least(:once)
      spec_helper_silence_stdout() do
        get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      end

      instances = ApiTools::ServiceMiddleware.logger.instances
      expect( instances[ 0 ] ).to be_a( ApiTools::Logger::StreamWriter )
      expect( instances[ 1 ] ).to be_a( ApiTools::ServiceMiddleware::AMQPLogWriter )
      expect( ApiTools::ServiceMiddleware.logger.level ).to eq( :debug )
    end

    it 'has the expected "production" mode loggers' do
      force_logging_to( 'production' )

      expect_any_instance_of(FakeAlchemy).to receive(:send_message).at_least(:once)
      get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      instances = ApiTools::ServiceMiddleware.logger.instances
      expect( instances[ 0 ] ).to be_a( ApiTools::ServiceMiddleware::AMQPLogWriter )
      expect( ApiTools::ServiceMiddleware.logger.level ).to eq( :info )
    end
  end
end
