class RSpecTestServiceExoticStubImplementation < Hoodoo::Services::Implementation
  def list( context )
    context.response.set_estimated_resources( [], 88 )
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

# Optional extra header hash is for middleware that intentionally adds headers
shared_examples 'an AMQP-based middleware/client endpoint' do |optional_extra_header_hash|
  before :each do
    @optional_extra_header_hash = optional_extra_header_hash || {}
    @old_queue = ENV[ 'AMQ_URI' ]

    ENV[ 'AMQ_URI' ] = 'amqp://test:test@127.0.0.1'
    Hoodoo::Services::Middleware.clear_queue_configuration_cache!

    @mw = Hoodoo::Services::Middleware.new( RSpecTestServiceExoticStub.new )

    @cvar = false
    if Hoodoo::Services::Middleware.class_variable_defined?( '@@alchemy' )
      @cvar = true
      @cvar_val = Hoodoo::Services::Middleware.class_variable_get( '@@alchemy' )
    end

    # Need to blow away the discoverer's local cache or the simulation will
    # never attempt to run on queue.

    discoverer = @mw.instance_variable_get( '@discoverer' )
    discoverer.instance_variable_set( '@known_local_resources', {} ) # Hack for test!
  end

  after :each do
    ENV[ 'AMQ_URI' ] = @old_queue
    Hoodoo::Services::Middleware.clear_queue_configuration_cache!

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

  it 'returns known queue endpoint locations' do
    location = @mw.instance_variable_get( '@discoverer' ).discover( :Version, 2 )
    expect( location ).to be_a( Hoodoo::Services::Discovery::ForAMQP )
    expect( location.routing_path ).to eq( '/2/Version' )
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

    def run_expectations( action, full_path, mock_method, mock_query, mock_remote, mock_response )
      expect_any_instance_of( Hoodoo::Services::Discovery::ByFlux ).to receive(
        :discover_remote
      ).and_return(
        mock_remote
      )

      if mock_query
        mock_query = Hoodoo::Utilities.stringify( mock_query )
        mock_query[ 'search' ] = URI.encode_www_form( mock_query[ 'search' ] ) if ( mock_query[ 'search' ].is_a?( ::Hash ) )
        mock_query[ 'filter' ] = URI.encode_www_form( mock_query[ 'filter' ] ) if ( mock_query[ 'filter' ].is_a?( ::Hash ) )
      end

      expect( @mock_alchemy ).to receive( :send_request_to_resource ).once do | message |
        expect( message ).to eq( {
          'scheme'     => 'http',
          'verb'       => mock_method,

          'host'       => 'localhost',
          'port'       => 80,
          'path'       => full_path,
          'query'      => mock_query,

          'session_id' => @interaction.context.session.session_id,
          'body'       => action == :create || action == :update ? '{}' : '',
          'headers'    => {
            'Content-Type' => 'application/json; charset=utf-8',
            'Content-Language' => 'fr',
            'Accept-Language' => 'fr',
            'X-Interaction-ID' => @interaction.interaction_id,
            'X-Session-ID' => @interaction.context.session.session_id
          }.merge!( @optional_extra_header_hash ),
        } )
      end.and_return( mock_response )
    end

    # All the other tests in this section run with @mw having no
    # local services "as far as it is concerned" via the before-each
    # code above. We want to make sure that service announcement when
    # on-queue *does* announce locally (because at one point it did
    # not, which was a bug) so this test provides that coverage.
    #
    it 'runs local discovery unless that is knocked out' do

      # @mw has local discovery knocked out, so build a new
      # one that doesn't. This will have the local discovery data
      # available still.
      #
      @mw = Hoodoo::Services::Middleware.new( RSpecTestServiceExoticStub.new )

      mock_path   = '/2/Version/'
      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      # We expect local discovery, so no discover_remote call.

      expect_any_instance_of( Hoodoo::Services::Discovery::ByFlux ).to_not receive( :discover_remote )
      endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )

      # The endpoint should've been called locally; the implementation at
      # the top of this file sets an empty array with dataset size 99 *and*
      # an estimated dataset size of 88.

      mock_result = endpoint.list()
      expect( mock_result ).to be_empty
      expect( mock_result.dataset_size ).to eq( 99 )
      expect( mock_result.estimated_dataset_size ).to eq( 88 )
    end

    it 'complains about a missing Alchemy instance' do
      mock_path = '/2/Version/'

      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      expect_any_instance_of( Hoodoo::Services::Discovery::ByFlux ).to receive(
        :discover_remote
      ).and_return(
        mock_remote
      )

      endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )

      # Fragile! Hack for test only.
      endpoint.instance_variable_get( '@wrapped_endpoint' ).alchemy = nil

      mock_response = {
        'status_code' => 200,
        'body' => '{"_data":[]}'
      }

      expect {
        mock_result = endpoint.list()
      }.to raise_error( RuntimeError, 'Hoodoo::Client::Endpoint::AMQP cannot be used unless an Alchemy instance has been provided' )
    end

    it 'calls #list over Alchemy and handles 200' do
      mock_path   = '/2/Version'
      mock_method = 'GET'
      mock_query  = { :search => { :foo => :bar } }

      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      mock_response = {
        'status_code' => 200,
        'body' => '{"_data":[]}'
      }

      run_expectations( :list, mock_path + '/', mock_method, mock_query, mock_remote, mock_response )

      endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
      mock_result = endpoint.list( mock_query )

      expect( mock_result ).to eq( Hoodoo::Client::AugmentedArray.new )
    end

    it 'calls #show over Alchemy and handles 200' do
      mock_path   = '/2/Version'
      mock_method = 'GET'
      mock_query  = { :search => { :foo => :bar } }

      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      mock_response = {
        'status_code' => 200,
        'body' => '{}'
      }

      run_expectations( :show, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

      endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
      mock_result = endpoint.show( 'ident', mock_query )

      expect( mock_result ).to eq( Hoodoo::Client::AugmentedHash.new )
    end

    it 'calls #create over Alchemy and handles 200' do
      mock_path   = '/2/Version'
      mock_method = 'POST'
      mock_query  = { :search => { :foo => :bar } }

      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      mock_response = {
        'status_code' => 200,
        'body' => '{}'
      }

      run_expectations( :create, mock_path + '/', mock_method, mock_query, mock_remote, mock_response )

      endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
      mock_result = endpoint.create( {}, mock_query )

      expect( mock_result ).to eq( Hoodoo::Client::AugmentedHash.new )
    end

    it 'calls #update over Alchemy and handles 200' do
      mock_path   = '/2/Version'
      mock_method = 'PATCH'
      mock_query  = { :search => { :foo => :bar } }

      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      mock_response = {
        'status_code' => 200,
        'body' => '{}'
      }

      run_expectations( :update, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

      endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
      mock_result = endpoint.update( 'ident', {}, mock_query )

      expect( mock_result ).to eq( Hoodoo::Client::AugmentedHash.new )
    end

    it 'calls #delete over Alchemy and handles 200' do
      mock_path   = '/2/Version'
      mock_method = 'DELETE'
      mock_query  = { :search => { :foo => :bar } }

      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      mock_response = {
        'status_code' => 200,
        'body' => '{}'
      }

      run_expectations( :delete, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

      endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
      mock_result = endpoint.delete( 'ident', mock_query )

      expect( mock_result ).to eq( Hoodoo::Client::AugmentedHash.new )
    end

    it 'calls #show over Alchemy and handles 408' do
      mock_path   = '/2/Version'
      mock_method = 'GET'
      mock_query  = { :search => { :foo => :bar } }

      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      mock_response = AlchemyFlux::TimeoutError

      run_expectations( :show, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

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
      mock_path   = '/2/Version'
      mock_method = 'GET'
      mock_query  = { :search => { :foo => :bar } }

      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      mock_response = AlchemyFlux::MessageNotDeliveredError

      run_expectations( :show, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

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

    it 'calls #show over Alchemy and handles unusual HTTP status codes' do
      mock_path   = '/2/Version'
      mock_method = 'GET'
      mock_query  = { :search => { :foo => :bar } }

      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      bad_body_data = '499 Unusual Code'
      mock_response = {
        'status_code' => 499,
        'body' => bad_body_data
      }

      run_expectations( :show, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

      endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
      mock_result = endpoint.show( 'ident', mock_query )

      expect( mock_result ).to be_a( Hoodoo::Client::AugmentedHash )
      expect( mock_result.platform_errors ).to_not be_nil

      errors = mock_result.platform_errors.render( Hoodoo::UUID.generate )

      expect( errors ).to have_key( 'errors' )
      expect( errors[ 'errors' ] ).to be_a( Array )
      expect( errors[ 'errors' ][ 0 ] ).to_not be_nil

      expect( errors[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.fault' )
      expect( errors[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'Unexpected raw HTTP status code 499 with non-JSON response' )
      expect( errors[ 'errors' ][ 0 ][ 'reference' ] ).to eq( "#{ bad_body_data }" )
    end

    it 'calls #show over Alchemy and handles unrecognised return types' do
      mock_path   = '/2/Version'
      mock_method = 'GET'
      mock_query  = { :search => { :foo => :bar } }

      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      bad_body_data = '500 Internal Server Error'
      mock_response = Object.new

      run_expectations( :show, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

      endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
      mock_result = endpoint.show( 'ident', mock_query )

      expect( mock_result ).to be_a( Hoodoo::Client::AugmentedHash )
      expect( mock_result.platform_errors ).to_not be_nil

      errors = mock_result.platform_errors.render( Hoodoo::UUID.generate )

      expect( errors ).to have_key( 'errors' )
      expect( errors[ 'errors' ] ).to be_a( Array )
      expect( errors[ 'errors' ][ 0 ] ).to_not be_nil

      expect( errors[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.fault' )
      expect( errors[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'Unexpected raw HTTP status code 500 with non-JSON response' )
      expect( errors[ 'errors' ][ 0 ][ 'reference' ] ).to eq( "#{ bad_body_data }" )
    end

    it 'calls #show over Alchemy and handles 200 status but bad JSON' do
      mock_path   = '/2/Version'
      mock_method = 'GET'
      mock_query  = { :search => { :foo => :bar } }

      mock_remote = Hoodoo::Services::Discovery::ForAMQP.new(
        resource: 'Version',
        version: 2
      )

      bad_body_data = 'Not JSON'
      mock_response = {
        'status_code' => 200,
        'body' => bad_body_data
      }

      run_expectations( :show, mock_path + '/ident', mock_method, mock_query, mock_remote, mock_response )

      endpoint = @mw.inter_resource_endpoint_for( 'Version', 2, @interaction )
      mock_result = endpoint.show( 'ident', mock_query )

      expect( mock_result ).to be_a( Hoodoo::Client::AugmentedHash )
      expect( mock_result.platform_errors ).to_not be_nil

      errors = mock_result.platform_errors.render( Hoodoo::UUID.generate )

      expect( errors ).to have_key( 'errors' )
      expect( errors[ 'errors' ] ).to be_a( Array )
      expect( errors[ 'errors' ][ 0 ] ).to_not be_nil

      expect( errors[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.fault' )
      expect( errors[ 'errors' ][ 0 ][ 'message'   ] ).to eq( 'Could not parse retrieved body data despite receiving HTTP status code 200' )
      expect( errors[ 'errors' ][ 0 ][ 'reference' ] ).to eq( "#{ bad_body_data }" )
    end
  end
end
