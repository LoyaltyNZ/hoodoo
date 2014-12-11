# Test coverage (mostly hypothetical, just to ensure no syntax errors etc. via
# full code coverage) for esoteric/exotic communcation methods such as on-queue
# endpoints or HTTPS transport for local machine inter-resource calls.

require 'spec_helper'

describe ApiTools::ServiceMiddleware do

  class RSpecTestServiceExoticStubImplementation < ApiTools::ServiceImplementation
  end

  class RSpecTestServiceExoticStubInterface < ApiTools::ServiceInterface
    interface :Version do
      endpoint :version, RSpecTestServiceExoticStubImplementation
      version 2
    end
  end

  class RSpecTestServiceExoticStub < ApiTools::ServiceApplication
    comprised_of RSpecTestServiceExoticStubInterface
  end

  context 'on queue' do
    before :each do
      ENV[ 'AMQ_ENDPOINT' ] = 'amqp://test:test@127.0.0.1'
      @mw = ApiTools::ServiceMiddleware.new( RSpecTestServiceExoticStub.new )

      @no_cvar = true
      if ApiTools::ServiceMiddleware.class_variable_defined?( '@@alchemy' )
        @no_cvar = false
        @cvar_val = ApiTools::ServiceMiddleware.class_variable_get( '@@alchemy' )
      end
    end

    after :each do
      ENV.delete( 'AMQ_ENDPOINT' )

      if ApiTools::ServiceMiddleware.class_variable_defined?( '@@alchemy' )
        if @no_cvar == true
          ApiTools::ServiceMiddleware.remove_class_variable( '@@alchemy' )
        else
          @cvar_val = ApiTools::ServiceMiddleware.class_variable_set( '@@alchemy', @cvar_val)
        end
      end
    end

    it 'knows it is on-queue' do
      expect( ApiTools::ServiceMiddleware.on_queue? ).to eq( true )
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
      @mw.instance_variable_set( '@rack_request', OpenStruct.new )

      if ApiTools::ServiceMiddleware.class_variable_defined?( '@@alchemy' )
        ApiTools::ServiceMiddleware.remove_class_variable( '@@alchemy' )
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
      @mw.instance_variable_set( '@rack_request', OpenStruct.new )

      mock_alchemy = OpenStruct.new
      ApiTools::ServiceMiddleware.class_variable_set( '@@alchemy', mock_alchemy )

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
            :session_id => nil,
            :host       => nil,
            :port       => nil,
            :body       => '',
            :query      => mock_query,
            :headers    => {
              'Content-Type' => 'application/json; charset=utf-8',
              'Content-Language' => nil,
              'X-Interaction-ID' => '+', # "+" == ApiTools 'not present' marker
              'X-Session-ID' => '+'
            },
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

      expect( mock_result ).to eq( ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedHash.new )
    end
  end
end
