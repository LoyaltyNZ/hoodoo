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

describe ApiTools::ServiceMiddleware do

  before :each do
    @old_logger = ApiTools::Logger.logger
    ApiTools::Logger.logger = ApiTools::ServiceMiddleware::StructuredLogger
  end

  after :each do
    ApiTools::Logger.logger = @old_logger
  end

  context 'without Alchemy' do

    def app
      Rack::Builder.new do
        use ApiTools::ServiceMiddleware
        run TestLogServiceApplication.new
      end
    end

    it 'logs to stdout with the structured logger' do
      expect(ApiTools::ServiceMiddleware::StructuredLogger).to receive(:report).at_least(:once).and_call_original
      expect($stdout).to receive(:puts).at_least(:once) do | *args |
        $stderr.puts( args ) # Echo output to stderr for test.log
      end
      get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(200)
    end
  end

  context 'with fake Alchemy' do

    class FakeAlchemy
      def initialize(app)
        @app = app
      end
      def call(env)
        env['rack.alchemy'] = self
        @app.call(env)
      end
      def send_message()
      end
    end

    def app
      Rack::Builder.new do
        use FakeAlchemy
        use ApiTools::ServiceMiddleware
        run TestLogServiceApplication.new
      end
    end

    it 'logs to stdout with the structured logger' do

      # So obviously we should be calling the structured logger.
      #
      expect(ApiTools::ServiceMiddleware::StructuredLogger).to receive(:report).at_least(:once).and_call_original

      # Since we're running with FakeAlchemy middleware and it sets
      # itself up as the alchemy endpoint, we expect it to receive a
      # "send_message" call as the structured logger tries to log to
      # the queue.
      #
      expect_any_instance_of(FakeAlchemy).to receive(:send_message).at_least(:once)

      # In development and test modes, the middleware copies terse
      # versions of its queue-logged messages to the console with the
      # prefix "ECHO ", so we expect that too.
      #
      expect($stdout).to receive(:puts).at_least(:once) do | string, *args |
        expect(string.include?('ECHO ')).to eq(true)
        $stderr.puts( string, args ) # Echo output to stderr for test.log
      end

      get '/v1/test_log/hello', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      expect(last_response.status).to eq(200)
    end
  end
end

describe ApiTools::ServiceMiddleware::AMQPLogMessage do

  require 'msgpack'

  let(:hash) do
    {
      :id => '1',
      :level => :info,
      :component => :RSpec,
      :code => 'hello',
      :data => { 'this' => 'that' },
      :interaction_id => '2',
      :participant_id => '3',
      :outlet_id => '4'
    }
  end

  it 'serializes' do
    obj = described_class.new( hash )
    expect( obj.serialize ).to eq( MessagePack.pack( hash ) )
  end

  it 'deserializes' do
    obj = described_class.new( hash )
    expect( obj.serialize ).to eq( MessagePack.pack( hash ) )
    obj.id = nil # Clear some instance vars
    obj.level = nil
    obj.deserialize # Should reset instance vars based on prior serialization
    expect( obj.serialize ).to eq( MessagePack.pack( hash ) )
  end
end
