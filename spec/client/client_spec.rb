# So this is heavy... We need:
#
# - A real resource endpoint that implements the Session API
# - Another endpoint with public actions to test without a session
# - Some of that enpoint which requires a session
# - The endpoint to be available by convention or DRb
#
# In passing we necessarily end up with quite a lot of test coverage for
# some of the endpoint and discovery code.

require 'spec_helper.rb'

##############################################################################
# Session resource
##############################################################################

class RSpecClientTestSessionImplementation < Hoodoo::Services::Implementation
  def create( context )

    session_id = Hoodoo::UUID.generate()
    test_session = Hoodoo::Services::Middleware.test_session().dup
    test_session.session_id = session_id
    Hoodoo::Services::Middleware.set_test_session( test_session )

    # All the session reading code really cares about is 'id', but let's
    # return something that looks very like a documented Session anyway.
    #
    context.response.set_resource(
      'id'         => session_id,
      'created_at' => Time.now.utc.iso8601,
      'kind'       => 'RSpecClientTestSession',
      'caller_id'  => context.request.body[ 'caller_id' ],
      'expires_at' => ( Time.now.utc + 24*60*60 ).iso8601
    )
  end
end

class RSpecClientTestSessionInterface < Hoodoo::Services::Interface
  interface :RSpecClientTestSession do
    endpoint :r_spec_client_test_sessions, RSpecClientTestSessionImplementation
    public_actions :create
  end
end

##############################################################################
# Target resource
##############################################################################

class RSpecClientTestTargetImplementation < Hoodoo::Services::Implementation

  public

    # This will be a public action

    def show( context )
      context.response.set_resource( mock( context ) )
    end

    # The rest will be protected actions

    def list( context )
      context.response.set_resources(
        [ mock( context ), mock( context ), mock( context ) ],
        3
      )
    end

    def create( context )
      context.response.set_resource( mock( context ) )
    end

    def update( context )
      context.response.set_resource( mock( context ) )
    end

    def delete( context )
      context.response.set_resource( mock( context ) )
    end

  private
    def mock( context )
      {
        'id'         => context.request.ident || Hoodoo::UUID.generate(),
        'created_at' => Time.now.utc.iso8601,
        'kind'       => 'RSpecClientTestTarget'
      }
    end
end

class RSpecClientTestTargetInterface < Hoodoo::Services::Interface
  interface :RSpecClientTestTarget do
    endpoint :r_spec_client_test_targets, RSpecClientTestTargetImplementation
    public_actions :show
    actions :list, :create, :update, :delete
  end
end

##############################################################################
# One endpoint for both resources
#
# When we use by-convention discovery, a single base host is assumed. If we
# were to try and start multiple resource endpoints in their own HTTP threads
# on localhost, you'd have different port numbers and thus a different base
# URI, which by-convention discovery can't find (even though by-DRb can).
##############################################################################

class RSpecClientTestService < Hoodoo::Services::Service
  comprised_of RSpecClientTestSessionInterface,
               RSpecClientTestTargetInterface
end

##############################################################################
# Tests
##############################################################################

describe Hoodoo::Client do

  before :all do
    @old_test_session = Hoodoo::Services::Middleware.test_session()
    @port = spec_helper_start_svc_app_in_thread_for( RSpecClientTestService )
  end

  after :all do
    Hoodoo::Services::Middleware.set_test_session( @old_test_session )
  end

  context 'without auto-session' do
    shared_examples Hoodoo::Client do
      it 'can contact public actions' do
        mock_ident = Hoodoo::UUID.generate()

        result = @endpoint.show( mock_ident )

        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
      end
    end

    context 'and by drb' do
      before :each do
        drb_port = URI.parse( Hoodoo::Services::Discovery::ByDRb::DRbServer.uri() ).port

        @client = Hoodoo::Client.new(
          drb_port:     drb_port,
          auto_session: false
        )

        @endpoint = @client.resource( :RSpecClientTestTarget )
      end

      it_behaves_like Hoodoo::Client
    end

    context 'and by convention' do
      before :each do
        @client = Hoodoo::Client.new(
          base_uri:     "http://localhost:#{ @port }",
          auto_session: false
        )

        @endpoint = @client.resource( :RSpecClientTestTarget )
      end

      it_behaves_like Hoodoo::Client
    end
  end

  context 'with auto-session' do
  end
end
