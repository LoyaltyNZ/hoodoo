require 'spec_helper.rb'

# We need to run these tests in order. First a bunch of shared examples
# run. Then we check to see if hook methods were invoked in passing. You
# can't do that in an 'after' hook as exceptions therein cause warnings
# to be printed, but don't cause test failures.
#
describe Hoodoo::Monkey::Patch::NewRelicTracedAMQP, :order => :defined do

  # Not every test in the 'an AMQP-based middleware/client endpoint' shared
  # example group will provoke a request. We cannot expect to have the
  # NewRelic hooks called for every example. We *can* expect them to be
  # called several times though, so use 'allow' to track those calls and
  # count them.
  #
  before :all do
    @@endpoint_do_amqp_count       = 0
    @@newrelic_crossapp_count      = 0
    @@newrelic_agent_disable_count = 0

    module NewRelic
      class Agent
        class CrossAppTracing
        end
      end
    end

    Hoodoo::Monkey.enable( extension_module: Hoodoo::Monkey::Patch::NewRelicTracedAMQP )
  end

  after :all do
    Hoodoo::Monkey.disable( extension_module: Hoodoo::Monkey::Patch::NewRelicTracedAMQP )
    Object.send( :remove_const, :NewRelic )
  end

  before :each do
    expect( Hoodoo::Client::Endpoint::AMQP.ancestors ).to include( Hoodoo::Monkey::Patch::NewRelicTracedAMQP::InstanceExtensions )

    original_do_amqp = Hoodoo::Client::Endpoint::AMQP.instance_method( :do_amqp )

    # Count the number of times the AMQP endpoint's non-patched private
    # "do_amqp" method is called. This calls through to the monkey patch
    # under test, so we expect an equal number of calls to the NewRelic
    # methods - *except* that "do_amqp" can deliberately raise an
    # exception and there is test coverage for it. Thus, only increment
    # the count if the call was successful - no exception raised.
    #
    allow_any_instance_of( Hoodoo::Client::Endpoint::AMQP ).to receive( :do_amqp ) do | instance, description_of_request |
      result = original_do_amqp.bind( instance ).call( description_of_request )
      @@endpoint_do_amqp_count += 1
      result
    end

    allow( NewRelic::Agent::CrossAppTracing ).to receive( :tl_trace_http_request ) do | newrelic_request, &block |
      @@newrelic_crossapp_count += 1

      expect( newrelic_request ).to be_a( Hoodoo::Monkey::Patch::NewRelicTracedAMQP::AMQPNewRelicRequestWrapper )
      block.call()
    end

    allow( NewRelic::Agent ).to receive( :disable_all_tracing ) do | &block |
      @@newrelic_agent_disable_count += 1

      result = block.call()
      expect( result ).to be_a( Hoodoo::Monkey::Patch::NewRelicTracedAMQP::AMQPNewRelicResponseWrapper )
      result
    end
  end

  it_behaves_like 'an AMQP-based middleware/client endpoint'

  context 'afterwards' do
    it 'has non-zero NewRelic method call counts' do
      expect( @@endpoint_do_amqp_count       ).to be > 5
      expect( @@newrelic_crossapp_count      ).to eq( @@endpoint_do_amqp_count )
      expect( @@newrelic_agent_disable_count ).to eq( @@endpoint_do_amqp_count )
    end
  end
end

describe Hoodoo::Monkey::Patch::NewRelicTracedAMQP::AMQPNewRelicRequestWrapper do
  before :each do
    @full_uri     = 'https://test.com:8080/1/Person/1234?_embed=Birthday'
    @http_message = {
      'scheme'  => 'http',
      'verb'    => 'GET',

      'host'    => 'test.com',
      'port'    => '8080',
      'path'    => '/1/Person/1234',
      'query'   => { '_embed' => 'Birthday' },

      'headers' => { 'CONTENT_TYPE' => 'application/json; charset=utf-8' },
      'body'    => ''
    }

    @wrapper = described_class.new( @http_message, @full_uri )
  end

  it 'reports the correct "type" value' do
    expect( @wrapper.type ).to eq( 'Hoodoo::Monkey::Patch::NewRelicTracedAMQP::AMQPNewRelicRequestWrapper' )
  end

  it 'reports the correct "host" value' do
    expect( @wrapper.host ).to eq( @http_message[ 'host' ] )
  end

  it 'reports the correct "method" value' do
    expect( @wrapper.method ).to eq( @http_message[ 'verb' ] )
  end

  it 'reports the correct "uri" value' do
    expect( @wrapper.uri ).to eq( @full_uri )
  end

  it 'can read headers' do
    expect( @wrapper[ 'CONTENT_TYPE' ] ).to eq( @http_message[ 'headers' ][ 'CONTENT_TYPE' ] )
  end

  it 'can write headers' do
    @wrapper[ 'HTTP_X_FOO' ] = '23'
    expect( @http_message[ 'headers' ][ 'HTTP_X_FOO' ] ).to eq( '23' )
  end
end

describe Hoodoo::Monkey::Patch::NewRelicTracedAMQP::AMQPNewRelicResponseWrapper do

  before :all do
    module NewRelic
      class Agent
        class CrossAppTracing
          NR_APPDATA_HEADER = 'X_Foo_AppData'
        end
      end
    end
  end

  before :each do
    @http_response = {
      'headers'      => { NewRelic::Agent::CrossAppTracing::NR_APPDATA_HEADER => '4321' },
      'CONTENT_TYPE' => 'application/json; charset=utf-8',
      'HTTP_X_FOO'   => '46'
    }

    @wrapper = described_class.new( @http_response )
  end

  after :all do
    Object.send( :remove_const, :NewRelic )
  end

  it 'accesses the NewRelic NR_APPDATA_HEADER correctly' do
    expect( @wrapper[ NewRelic::Agent::CrossAppTracing::NR_APPDATA_HEADER ] ).to eq( @http_response[ 'headers' ][ NewRelic::Agent::CrossAppTracing::NR_APPDATA_HEADER ] )
  end

  it 'accesses other headers correctly' do
    expect( @wrapper[ 'CONTENT_TYPE' ] ).to eq( @http_response[ 'CONTENT_TYPE' ] )
    expect( @wrapper[ 'HTTP_X_FOO'   ] ).to eq( @http_response[ 'HTTP_X_FOO'   ] )
  end
end
