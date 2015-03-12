# Test coverage (mostly hypothetical, just to ensure no typing errors etc. via
# full code coverage) for esoteric/exotic communcation methods such as on-queue
# endpoints or HTTPS transport for local machine inter-resource calls.

require 'spec_helper'
require 'alchemy-amq'

describe Hoodoo::Services::Middleware do

  class RSpecTestServiceExoticStubImplementation < Hoodoo::Services::Implementation
    def list( context )
      context.response.set_resources( [], 99 )
    end
  end

  class RSpecTestServiceExoticStubInterface < Hoodoo::Services::Interface
    interface :Version do
      endpoint :version, RSpecTestServiceExoticStubImplementation
      version 2
    end
  end

  class RSpecTestServiceExoticStub < Hoodoo::Services::Service
    comprised_of RSpecTestServiceExoticStubInterface
  end

  context 'on queue' do
    before :each do
      @old_queue = ENV[ 'AMQ_ENDPOINT' ]
      ENV[ 'AMQ_ENDPOINT' ] = 'amqp://test:test@127.0.0.1'
      @mw = Hoodoo::Services::Middleware.new( RSpecTestServiceExoticStub.new )

      @cvar = false
      if Hoodoo::Services::Middleware.class_variable_defined?( '@@alchemy' )
        @cvar = true
        @cvar_val = Hoodoo::Services::Middleware.class_variable_get( '@@alchemy' )
      end
    end

    after :each do
      ENV[ 'AMQ_ENDPOINT' ] = @old_queue

      if Hoodoo::Services::Middleware.class_variable_defined?( '@@alchemy' )
        if @cvar == true
          Hoodoo::Services::Middleware.class_variable_set( '@@alchemy', @cvar_val )
        else
          Hoodoo::Services::Middleware.remove_class_variable( '@@alchemy' )
        end
      end
    end

    it 'knows it is on-queue' do
      expect( Hoodoo::Services::Middleware.on_queue? ).to eq( true )
    end

    # TODO: Weak test! Assumes static mappings. Will need modification
    #       for generic Hoodoo.
    #
    it 'returns known queue endpoint locations' do
      location = @mw.instance_variable_get( '@discoverer' ).discover( :Version, 2 )
      expect( location ).to be_a( Hoodoo::Services::Discovery::ForAMQP )
      expect( location.queue_name ).to eq( 'service.utility' )
      expect( location.equivalent_path ).to eq( '/v2/version' )
    end

    it 'returns "nil" for unknown queue endpoint locations' do
      location = @mw.instance_variable_get( '@discoverer' ).discover( :NotAKnownResource, 2 )
      expect( location ).to be_nil
    end

    context 'calling Alchemy' do
      before :each do
        mw = Hoodoo::Services::Middleware.new( RSpecTestServiceExoticStub.new )
        @interaction = Hoodoo::Services::Middleware::Interaction.new(
          {},
          mw,
          Hoodoo::Services::Middleware.test_session()
        )
        @interaction.target_interface = OpenStruct.new
        @interaction.context.request.locale = 'fr'

        @mock_alchemy = OpenStruct.new
        Hoodoo::Services::Middleware.class_variable_set( '@@alchemy', @mock_alchemy )
      end

      def run_expectations( action, mock_queue, full_path, mock_method, mock_query, mock_remote, mock_response )
        expect_any_instance_of( Hoodoo::Services::Discovery::ByConsul ).to receive(
          :discover_remote
        ).and_return(
          mock_remote
        )

        expect( @mock_alchemy ).to receive( :http_request ).once do | queue, method, path, opts |
          expect( queue ).to eq( mock_queue )
          expect( method ).to eq( mock_method )
          expect( path ).to eq( full_path )
          expect( opts ).to eq(
            {
              :session_id => @interaction.context.session.session_id,
              :host       => 'localhost',
              :port       => 80,
              :body       => action == :create || action == :update ? '{}' : '',
              :query      => mock_query,
              :headers    => {
                'Content-Type' => 'application/json; charset=utf-8',
                'Content-Language' => 'fr',
                'X-Interaction-ID' => @interaction.interaction_id,
                'X-Session-ID' => @interaction.context.session.session_id
              }
            }
          )
        end.and_return( mock_response )
      end

      it 'complains about a missing Alchemy instance' do
        mock_queue  = 'service.utility'
        mock_path   = '/v2/version/'

        mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
          resource: 'Version',
          version: 2,
          queue_name: mock_queue,
          equivalent_path: mock_path
        )

        expect_any_instance_of( Hoodoo::Services::Discovery::ByConsul ).to receive(
          :discover_remote
        ).and_return(
          mock_remote
        )

        endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )

        # Fragile! Hack for test only.
        endpoint.instance_variable_get( '@wrapped_endpoint' ).alchemy = nil

        mock_response = AlchemyAMQ::HTTPResponse.new(
          :status_code => 200,
          :body => '{"_data":[]}'
        )

        expect {
          mock_result = endpoint.list()
        }.to raise_error( RuntimeError, 'Hoodoo::Client::Endpoint::AMQP cannot be used unless an Alchemy instance has been provided' )
      end

      it 'calls #list over Alchemy and handles 200' do
        mock_queue  = 'service.utility'
        mock_path   = '/v2/version'
        mock_method = 'GET'
        mock_query  = { :search => { :foo => :bar } }

        mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
          resource: 'Version',
          version: 2,
          queue_name: mock_queue,
          equivalent_path: mock_path
        )

        mock_response = AlchemyAMQ::HTTPResponse.new(
          :status_code => 200,
          :body => '{"_data":[]}'
        )

        run_expectations( :list, mock_queue, mock_path + '/', mock_method, mock_query, mock_remote, mock_response )

        endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
        mock_result = endpoint.list( mock_query )

        expect( mock_result ).to eq( Hoodoo::Client::AugmentedArray.new )
      end

      it 'calls #show over Alchemy and handles 200' do
        mock_queue  = 'service.utility'
        mock_path   = '/v2/version'
        mock_method = 'GET'
        mock_query  = { :search => { :foo => :bar } }

        mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
          resource: 'Version',
          version: 2,
          queue_name: mock_queue,
          equivalent_path: mock_path
        )

        mock_response = AlchemyAMQ::HTTPResponse.new(
          :status_code => 200,
          :body => '{}'
        )

        run_expectations( :show, mock_queue, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

        endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
        mock_result = endpoint.show( 'ident', mock_query )

        expect( mock_result ).to eq( Hoodoo::Client::AugmentedHash.new )
      end

      it 'calls #create over Alchemy and handles 200' do
        mock_queue  = 'service.utility'
        mock_path   = '/v2/version'
        mock_method = 'POST'
        mock_query  = { :search => { :foo => :bar } }

        mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
          resource: 'Version',
          version: 2,
          queue_name: mock_queue,
          equivalent_path: mock_path
        )

        mock_response = AlchemyAMQ::HTTPResponse.new(
          :status_code => 200,
          :body => '{}'
        )

        run_expectations( :create, mock_queue, mock_path + '/', mock_method, mock_query, mock_remote, mock_response )

        endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
        mock_result = endpoint.create( {}, mock_query )

        expect( mock_result ).to eq( Hoodoo::Client::AugmentedHash.new )
      end

      it 'calls #update over Alchemy and handles 200' do
        mock_queue  = 'service.utility'
        mock_path   = '/v2/version'
        mock_method = 'PATCH'
        mock_query  = { :search => { :foo => :bar } }

        mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
          resource: 'Version',
          version: 2,
          queue_name: mock_queue,
          equivalent_path: mock_path
        )

        mock_response = AlchemyAMQ::HTTPResponse.new(
          :status_code => 200,
          :body => '{}'
        )

        run_expectations( :update, mock_queue, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

        endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
        mock_result = endpoint.update( 'ident', {}, mock_query )

        expect( mock_result ).to eq( Hoodoo::Client::AugmentedHash.new )
      end

      it 'calls #delete over Alchemy and handles 200' do
        mock_queue  = 'service.utility'
        mock_path   = '/v2/version'
        mock_method = 'DELETE'
        mock_query  = { :search => { :foo => :bar } }

        mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
          resource: 'Version',
          version: 2,
          queue_name: mock_queue,
          equivalent_path: mock_path
        )

        mock_response = AlchemyAMQ::HTTPResponse.new(
          :status_code => 200,
          :body => '{}'
        )

        run_expectations( :delete, mock_queue, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

        endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
        mock_result = endpoint.delete( 'ident', mock_query )

        expect( mock_result ).to eq( Hoodoo::Client::AugmentedHash.new )
      end

      it 'calls #show over Alchemy and handles 408' do
        mock_queue  = 'service.utility'
        mock_path   = '/v2/version'
        mock_method = 'GET'
        mock_query  = { :search => { :foo => :bar } }

        mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
          resource: 'Version',
          version: 2,
          queue_name: mock_queue,
          equivalent_path: mock_path
        )

        mock_response = AlchemyAMQ::HTTPResponse.new(
          :status_code => 408,
          :body => '408 Timeout'
        )

        run_expectations( :show, mock_queue, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

        endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
        mock_result = endpoint.show( 'ident', mock_query )

        expect( mock_result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( mock_result.platform_errors ).to_not be_nil

        errors = mock_result.platform_errors.render( Hoodoo::UUID.generate )

        expect( errors ).to have_key( 'errors' )
        expect( errors[ 'errors' ] ).to be_a( Array )
        expect( errors[ 'errors' ][ 0 ] ).to have_key( 'code' )
        expect( errors[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.timeout' )
      end

      it 'calls #show over Alchemy and handles 404' do
        mock_queue  = 'service.utility'
        mock_path   = '/v2/version'
        mock_method = 'GET'
        mock_query  = { :search => { :foo => :bar } }

        mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
          resource: 'Version',
          version: 2,
          queue_name: mock_queue,
          equivalent_path: mock_path
        )

        mock_response = AlchemyAMQ::HTTPResponse.new(
          :status_code => 404,
          :body => '404 Not Found'
        )

        run_expectations( :show, mock_queue, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

        endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
        mock_result = endpoint.show( 'ident', mock_query )

        expect( mock_result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( mock_result.platform_errors ).to_not be_nil

        errors = mock_result.platform_errors.render( Hoodoo::UUID.generate )

        expect( errors ).to have_key( 'errors' )
        expect( errors[ 'errors' ] ).to be_a( Array )
        expect( errors[ 'errors' ][ 0 ] ).to have_key( 'code' )
        expect( errors[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.not_found' )
      end

      it 'calls #show over Alchemy and handles "unexpected" status codes' do
        mock_queue  = 'service.utility'
        mock_path   = '/v2/version'
        mock_method = 'GET'
        mock_query  = { :search => { :foo => :bar } }

        mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
          resource: 'Version',
          version: 2,
          queue_name: mock_queue,
          equivalent_path: mock_path
        )

        mock_response = AlchemyAMQ::HTTPResponse.new(
          :status_code => 499,
          :body => '499 Invented'
        )

        run_expectations( :show, mock_queue, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

        endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
        mock_result = endpoint.show( 'ident', mock_query )

        expect( mock_result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( mock_result.platform_errors ).to_not be_nil

        errors = mock_result.platform_errors.render( Hoodoo::UUID.generate )

        expect( errors ).to have_key( 'errors' )
        expect( errors[ 'errors' ] ).to be_a( Array )
        expect( errors[ 'errors' ][ 0 ] ).to have_key( 'code' )
        expect( errors[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.fault' )
        expect( errors[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'Unexpected raw HTTP status code 499 during inter-resource call' )
      end

      it 'calls #show over Alchemy and handles 200 status but bad JSON' do
        mock_queue  = 'service.utility'
        mock_path   = '/v2/version'
        mock_method = 'GET'
        mock_query  = { :search => { :foo => :bar } }

        mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
          resource: 'Version',
          version: 2,
          queue_name: mock_queue,
          equivalent_path: mock_path
        )

        mock_response = AlchemyAMQ::HTTPResponse.new(
          :status_code => 200,
          :body => 'Not JSON'
        )

        run_expectations( :show, mock_queue, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

        endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
        mock_result = endpoint.show( 'ident', mock_query )

        expect( mock_result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( mock_result.platform_errors ).to_not be_nil

        errors = mock_result.platform_errors.render( Hoodoo::UUID.generate )

        expect( errors ).to have_key( 'errors' )
        expect( errors[ 'errors' ] ).to be_a( Array )
        expect( errors[ 'errors' ][ 0 ] ).to have_key( 'code' )
        expect( errors[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.fault' )
        expect( errors[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'Could not parse body data returned from inter-resource call despite receiving HTTP status code 200' )
      end
    end
  end

  context 'over HTTPS' do
    before :all do
      @port = spec_helper_start_svc_app_in_thread_for(
        RSpecTestServiceExoticStub,
        true # Use SSL
      )
    end

    # In random order the test after this might work first, but the idea here
    # is just to make a normal Net::HTTP request over SSL to the service using
    # the appropriate spec_helper.rb support method, just to see if it's awake.
    # If not, we don't expect the middleware's internal routines to manage it!
    #
    it 'demonstrates working HTTPS generally' do
      response = spec_helper_http(
        port: @port,
        path: '/v2/version',
        ssl:  true
      )

      expect( response.code ).to eq( '200' )
    end

    # This is the *real* internal test, though done via calling down into the
    # middleware's private implementation rather than worrying about standing
    # up two services and making a 'real' inter-resource call across them.
    # That's done elsewhere over HTTP. We just want to know if HTTPS functions
    # at all from that same chunk of code here.
    #
    it 'attempts HTTPS communication' do

      # Set up a middleware instance and mock interaction

      mw = Hoodoo::Services::Middleware.new( RSpecTestServiceExoticStub.new )
      interaction = Hoodoo::Services::Middleware::Interaction.new(
        {},
        mw,
        Hoodoo::Services::Middleware.test_session()
      )
      interaction.target_interface = OpenStruct.new

      # Synthesise an HTTP(S) discovery result for 'Version' / v2 and use
      # it to build an HTTP(S) endpoint.

      mock_wrapped_discovery_result = Hoodoo::Services::Discovery::ForHTTP.new(
        resource: 'Version',
        version: 2,
        endpoint_uri: URI.parse( "https://127.0.0.1:#{ @port }/v2/version" )
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
    end
  end
end
