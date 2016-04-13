# Test coverage (mostly hypothetical, just to ensure no typing errors etc. via
# full code coverage) for esoteric/exotic communcation methods such as on-queue
# endpoints or HTTPS transport for local machine inter-resource calls.

require 'spec_helper'

describe Hoodoo::Services::Middleware do

  context 'on queue' do
    before :all do
      Hoodoo::Monkey.disable( extension_module: Hoodoo::Monkey::Patch::NewRelicTracedAMQP )
    end

    it_behaves_like 'an AMQP-based middleware/client endpoint'
  end

  context 'over HTTPS' do
    before :all do
      @port = spec_helper_start_svc_app_in_thread_for(
        RSpecTestServiceExoticStub, # See shared_examples/middleware_amqp.rb
        true # Use SSL
      )
    end

    # In random order the test after this might work first, but the idea here
    # is just to make a normal Net::HTTP request over SSL to the service using
    # the appropriate spec_helper.rb support method, just to see if it's awake.
    # If not, we don't expect the middleware's internal routines to manage it!
    #
    context 'demonstrates working HTTPS generally via the' do
      it 'custom endpoint route' do
        response = spec_helper_http(
          port: @port,
          path: '/v2/version',
          ssl:  true
        )

        expect( response.code ).to eq( '200' )
      end

      it 'de facto endpoint route' do
        response = spec_helper_http(
          port: @port,
          path: '/2/Version',
          ssl:  true
        )

        expect( response.code ).to eq( '200' )
      end
    end

    # This is the *real* internal test, though done via calling down into the
    # middleware's private implementation rather than worrying about standing
    # up two services and making a 'real' inter-resource call across them.
    # That's done elsewhere over HTTP. We just want to know if HTTPS functions
    # at all from that same chunk of code here.
    #
    it 'attempts HTTPS communication' do

      # Set up a middleware instance and mock interaction

      mw = Hoodoo::Services::Middleware.new( RSpecTestServiceExoticStub.new ) # See shared_examples/middleware_amqp.rb
      interaction = Hoodoo::Services::Middleware::Interaction.new(
        {},
        mw,
        Hoodoo::Services::Middleware.test_session()
      )
      interaction.target_interface = OpenStruct.new

      # Synthesise an HTTP(S) discovery result for 'Version' / v2 and use
      # it to build an HTTP(S) endpoint.

      mock_wrapped_discovery_result = Hoodoo::Services::Discovery::ForHTTP.new(
        resource:     'Version',
        version:      2,
        endpoint_uri: URI.parse( "https://127.0.0.1:#{ @port }/2/Version" ),
        ca_file:      'spec/files/ca/ca-cert.pem'
      )

      mock_wrapped_endpoint = Hoodoo::Client::Endpoint::HTTP.new(
        'Version',
        2,
        :session => Hoodoo::Services::Middleware.test_session(),
        :discovery_result => mock_wrapped_discovery_result
      )

      # Synthesise a remote resource discovery result for the HTTP(S) endpoint
      # built above and use that to make a remote call endpoint.

      discovery_result = Hoodoo::Services::Discovery::ForRemote.new(
        :resource         => 'Version',
        :version          => 2,
        :wrapped_endpoint => mock_wrapped_endpoint
      )

      endpoint = Hoodoo::Services::Middleware::InterResourceRemote.new(
        'Version',
        2,
        {
          :interaction      => interaction,
          :discovery_result => discovery_result
        }
      )

      # Use the endpoint.

      mock_result = endpoint.list()

      # Expect an empty *array* back, with dataset size. A Hash implies an error.

      expect( mock_result ).to eq( Hoodoo::Client::AugmentedArray.new )
      expect( mock_result.dataset_size ).to eq(99)
      expect( mock_result.estimated_dataset_size ).to eq( 88 )
      expect( mock_result.platform_errors.has_errors? ).to eq( false )
    end
  end
end
