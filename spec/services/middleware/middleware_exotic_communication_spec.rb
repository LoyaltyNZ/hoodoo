# Test coverage (mostly hypothetical, just to ensure no typing errors etc. via
# full code coverage) for esoteric/exotic communcation methods such as on-queue
# endpoints or HTTPS transport for local machine inter-resource calls.

require 'spec_helper'

describe Hoodoo::Services::Middleware do

  class RSpecTestServiceExoticStubImplementation < Hoodoo::Services::Implementation
    def list( context )
      context.response.set_resources( [] )
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
      location = @mw.send( :remote_service_for, :Version, 2 )
      expect( location ).to be_a( Hash )
      expect( location[ :queue ] ).to eq( 'service.utility' )
      expect( location[ :path ] ).to eq( '/v2/version' )
    end

    it 'returns "nil" for unknown queue endpoint locations' do
      location = @mw.send( :remote_service_for, :NotAKnownResource )
      expect( location ).to be_nil
    end

    it 'complains about missing Alchemy' do
      interaction_id = Hoodoo::UUID.generate()
      session_id = Hoodoo::UUID.generate()

      @mw.instance_variable_set( '@rack_request', OpenStruct.new )
      @mw.instance_variable_set( '@locale', 'fr' )
      @mw.instance_variable_set( '@interaction_id', interaction_id )
      @mw.instance_variable_set( '@session_id', session_id )

      if Hoodoo::Services::Middleware.class_variable_defined?( '@@alchemy' )
        Hoodoo::Services::Middleware.remove_class_variable( '@@alchemy' )
      end

      expect {
        @mw.send(
          :inter_resource_remote,
          {
            # Purely hypothetical; no actual call will be made
            :remote      => { :queue => 'service.utility', :path => '/v2/version' },
            :http_method => 'GET'
          }
        )
      }.to raise_error( RuntimeError, 'Inter-resource call requested on queue, but no Alchemy endpoint was sent in the Rack environment' )
    end

    it 'calls Alchemy' do
      interaction_id = Hoodoo::UUID.generate()
      session_id = Hoodoo::UUID.generate()

      @mw.instance_variable_set( '@rack_request', OpenStruct.new )
      @mw.instance_variable_set( '@locale', 'fr' )
      @mw.instance_variable_set( '@interaction_id', interaction_id )
      @mw.instance_variable_set( '@session_id', session_id )

      mock_alchemy = OpenStruct.new
      Hoodoo::Services::Middleware.class_variable_set( '@@alchemy', mock_alchemy )

      mock_queue  = 'service.utility'
      mock_path   = '/v2/version'
      mock_method = 'GET'
      mock_query  = { :search => { :foo => :bar } }

      mock_response = OpenStruct.new
      mock_response.body = '{}'

      expect( mock_alchemy ).to receive( :http_request ).once do | queue, method, path, opts |
        expect( queue ).to eq( mock_queue )
        expect( method ).to eq( mock_method )
        expect( path ).to eq( mock_path )
        expect( opts ).to eq(
          {
            :session_id => session_id,
            :host       => nil,
            :port       => nil,
            :body       => '',
            :query      => mock_query,
            :headers    => {
              'Content-Type' => 'application/json; charset=utf-8',
              'Content-Language' => 'fr',
              'X-Interaction-ID' => interaction_id,
              'X-Session-ID' => session_id
            }
          }
        )
      end.and_return( mock_response )

      mock_result = @mw.send(
        :inter_resource_remote,
        {
          # Purely hypothetical; no actual call will be made
          :remote      => { :queue => mock_queue, :path => mock_path },
          :http_method => mock_method,
          :query_hash  => mock_query
        }
      )

      expect( mock_result ).to eq( Hoodoo::Services::Middleware::Endpoint::AugmentedHash.new )
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
      mw = Hoodoo::Services::Middleware.new( RSpecTestServiceExoticStub.new )

      interaction_id = Hoodoo::UUID.generate()
      session_id = Hoodoo::UUID.generate()

      mw.instance_variable_set( '@rack_request', OpenStruct.new )
      mw.instance_variable_set( '@locale', 'fr' )
      mw.instance_variable_set( '@interaction_id', interaction_id )
      mw.instance_variable_set( '@session_id', session_id )

      mock_result = mw.send(
        :inter_resource_remote,
        {
          :remote      => "https://127.0.0.1:#{ @port }/v2/version",
          :http_method => 'GET'
        }
      )

      # Expect an empty *array* back. A Hash implies an error.

      expect( mock_result ).to eq( Hoodoo::Services::Middleware::Endpoint::AugmentedArray.new )
    end
  end
end
