require 'spec_helper'

# Most coverage for 'dated-at' is done in passing through all the various
# integration, inter-resource local and inter-resource remote tests in other
# files. This particular test file was originally created to check the
# following scenario:
#
# * Top-level incoming call hits #create in resource A
# * The payload indicates some sort of backdating is in use
# * Resource A calls resource B with a dated-at specifier
# * Resource B calls resource C without an explicit specifier
# * Resource C should inherit the dated-at context from B.

###############################################################################

# A#create calls B#show calls C#show.

class RSpecDatedAtAImplementation < Hoodoo::Services::Implementation
  def create( context )
    created_at   = Time.now
    backdated_to = context.request.body[ 'backdated_to' ]
    dated_at     = Hoodoo::Utilities.rationalise_datetime( backdated_to || created_at )

    if context.request.body[ 'use_resource_options' ]
      endpoint = context.resource( :RSpecDatedAtB, 1, { :dated_at => dated_at } )
    else
      endpoint = context.resource( :RSpecDatedAtB )
      endpoint.dated_at = dated_at
    end

    result = endpoint.show( context.request.body[ 'thing_to_show_in_b' ] )
    context.response.set_resource( result ) unless result.platform_errors.has_errors?
  end
end

class RSpecDatedAtBImplementation < Hoodoo::Services::Implementation
  def show( context )
    endpoint = context.resource( :RSpecDatedAtC )
    result = endpoint.show( context.request.ident + '_to_c' )
    context.response.set_resource( result ) unless result.platform_errors.has_errors?
  end
end

class RSpecDatedAtCImplementation < Hoodoo::Services::Implementation
  def show( context )
    context.response.set_resource( {
      'id' => context.request.ident,
      'dated_at' => context.request.dated_at.to_s
    } )
  end
end

class RSpecDatedAtAInterface < Hoodoo::Services::Interface
  interface :RSpecDatedAtA do
    endpoint :rspec_dated_at_a, RSpecDatedAtAImplementation
  end
end

class RSpecDatedAtBInterface < Hoodoo::Services::Interface
  interface :RSpecDatedAtB do
    endpoint :rspec_dated_at_b, RSpecDatedAtBImplementation
  end
end

class RSpecDatedAtCInterface < Hoodoo::Services::Interface
  interface :RSpecDatedAtC do
    endpoint :rspec_dated_at_c, RSpecDatedAtCImplementation
  end
end

# Three services to stand up individually for a remote inter-resource
# call check, one service to stand up on its own for a local call check.

class RSpecDatedAtAService < Hoodoo::Services::Service
  comprised_of RSpecDatedAtAInterface
end

class RSpecDatedAtBService < Hoodoo::Services::Service
  comprised_of RSpecDatedAtBInterface
end

class RSpecDatedAtCService < Hoodoo::Services::Service
  comprised_of RSpecDatedAtCInterface
end

class RSpecDatedAtAllService < Hoodoo::Services::Service
  comprised_of RSpecDatedAtAInterface,
               RSpecDatedAtBInterface,
               RSpecDatedAtCInterface
end

###############################################################################

describe Hoodoo::Services::Middleware do

  before :each do

    @test_uuid = Hoodoo::UUID.generate()
    @old_test_session = Hoodoo::Services::Middleware.test_session()
    @test_session = @old_test_session.dup
    permissions = Hoodoo::Services::Permissions.new # (this is "default-else-deny")
    permissions.set_default_fallback( Hoodoo::Services::Permissions::ALLOW )
    @test_session.permissions = permissions
    @test_session.scoping = @test_session.scoping.dup
    @test_session.scoping.authorised_http_headers = [ 'HTTP_X_DATED_AT' ]
    Hoodoo::Services::Middleware.set_test_session( @test_session )

  end

  after :each do

    Hoodoo::Services::Middleware.set_test_session( @old_test_session )

  end

  context 'deep local calls' do
    after :all do
      Hoodoo::Services::Middleware.flush_services_for_test()
    end

    def app
      Rack::Builder.new do
        use Hoodoo::Services::Middleware
        run RSpecDatedAtAllService.new
      end
    end

    def run_test_with_resource_options_boolean_of( value )
      now = DateTime.now

      data = {
        :backdated_to => Hoodoo::Utilities.nanosecond_iso8601( now ),
        :use_resource_options => value,
        :thing_to_show_in_b => 'hello'
      }

      post '/v1/rspec_dated_at_a',
           data.to_json,
           { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      expect( last_response.status ).to eq( 200 )
      result = JSON.parse( last_response.body )

      expect( result ).to eq( {
        'id' => 'hello_to_c',
        'dated_at' => now.to_s
      } )
    end

    it 'passes dates through properly via context options' do
      run_test_with_resource_options_boolean_of( true )
    end

    it 'passes dates through properly via endpoint options' do
      run_test_with_resource_options_boolean_of( false )
    end
  end

  context 'deep remote calls' do
    after :all do
      Hoodoo::Services::Middleware.flush_services_for_test()
    end

    before :all do
      @port = spec_helper_start_svc_app_in_thread_for( RSpecDatedAtAService )
              spec_helper_start_svc_app_in_thread_for( RSpecDatedAtBService )
              spec_helper_start_svc_app_in_thread_for( RSpecDatedAtCService )
    end

    def run_test_with_resource_options_boolean_of( value )
      now = DateTime.now

      data = {
        :backdated_to => Hoodoo::Utilities.nanosecond_iso8601( now ),
        :use_resource_options => value,
        :thing_to_show_in_b => 'hello'
      }

      response = spec_helper_http(
        klass:   Net::HTTP::Post,
        port:    @port,
        path:    '/v1/rspec_dated_at_a',
        body:    data.to_json,
        headers: { 'Content-Type' => 'application/json; charset=utf-8' }
      )

      expect( response.code ).to eq( '200' )
      result = JSON.parse( response.body )

      expect( result ).to eq( {
        'id' => 'hello_to_c',
        'dated_at' => now.to_s
      } )
    end

    it 'passes dates through properly via context options' do
      run_test_with_resource_options_boolean_of( true )
    end

    it 'passes dates through properly via endpoint options' do
      run_test_with_resource_options_boolean_of( false )
    end
  end
end
