# So this is heavy... We need:
#
# - A real resource endpoint that implements the Session API
# - Another endpoint with public actions to test without a session
# - Some of that enpoint which requires a session
# - The endpoint to be available by convention or DRb
#
# In passing we necessarily end up with quite a lot of test coverage for
# some of the endpoint and discovery code.

require 'securerandom'
require 'spec_helper.rb'

##############################################################################
# Session resource
##############################################################################

class RSpecClientTestSessionImplementation < Hoodoo::Services::Implementation
  def create( context )

    session_id = Hoodoo::UUID.generate()
    test_session = Hoodoo::Services::Middleware::DEFAULT_TEST_SESSION.dup
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

# This resource 'echoes back' some of the query and body data in its
# responses so we can check to see if things seem to be passed through
# the layers properly. It's not exhaustive.
#
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
        'kind'       => 'RSpecClientTestTarget',
        'language'   => context.request.locale,
        'embeds'     => context.request.embeds,
        'body_hash'  => context.request.body,
        'dated_at'   => context.request.dated_at.nil? ? nil : Hoodoo::Utilities.nanosecond_iso8601( context.request.dated_at )
      }
    end
end

class RSpecClientTestTargetInterface < Hoodoo::Services::Interface
  interface :RSpecClientTestTarget do
    endpoint :r_spec_client_test_targets, RSpecClientTestTargetImplementation
    public_actions :show
    actions :list, :create, :update, :delete
    embeds :foo, :bar, :baz
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

  # Set @locale, @expected_locale (latter for 'to eq(...)' matching),
  # @dated_at, @expected_data_at (same deal), @client and callable @endpoint
  # up, passing the given options to the Hoodoo::Client constructor, with
  # randomised locale merged in. Conversion to lower case is checked
  # implicitly, with a mixed case locale generated (potentially) by random
  # but the 'downcase' version being used for 'expect's.
  #
  # Through the use of random switches, we (eventually!) get test coverage
  # on locale specified (or not) given to the Client, plus override locale
  # (or not) and a dated-at date/time (or not) given to the Endpoint.
  #
  def set_vars_for( opts )
    @locale            = rand( 2 ) == 0 ? nil : SecureRandom.urlsafe_base64(2)
    @expected_locale   = @locale.nil? ? 'en-nz' : @locale.downcase
    @client            = Hoodoo::Client.new( opts.merge( :locale => @locale ) )

    @dated_at          = rand( 2 ) == 0 ? nil : DateTime.now
    @expected_dated_at = @dated_at.nil? ? nil : Hoodoo::Utilities.nanosecond_iso8601( @dated_at )

    endpoint_opts = { :dated_at => @dated_at }

    if rand( 2 ) == 0
      override_locale          = SecureRandom.urlsafe_base64(2)
      endpoint_opts[ :locale ] = override_locale
      @expected_locale         = override_locale.downcase
    end

    @endpoint = @client.resource( :RSpecClientTestTarget, 1, endpoint_opts )
  end

  ##############################################################################
  # No automatic session acquisition and no session
  ##############################################################################

  context 'without any session' do
    shared_examples Hoodoo::Client do
      it 'can contact public actions' do
        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'foo', 'baz' ]
        query_hash = { '_embed' => embeds }

        result = @endpoint.show( mock_ident )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
        expect( result[ 'embeds' ] ).to eq( [] )
        expect( result[ 'language' ] ).to eq( @expected_locale )
        expect( result[ 'dated_at' ] ).to eq( @expected_dated_at )

        result = @endpoint.show( mock_ident, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
        expect( result[ 'embeds' ] ).to eq( embeds )
        expect( result[ 'language' ] ).to eq( @expected_locale )
        expect( result[ 'dated_at' ] ).to eq( @expected_dated_at )
      end

      it 'cannot contact protected actions' do
        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( true )
        expect( result.platform_errors.errors[ 0 ][ 'code' ] ).to eq( 'platform.invalid_session' )
      end
    end

    before :each do
      Hoodoo::Services::Middleware.set_test_session( nil )
    end

    context 'and by DRb' do
      before :each do
        set_vars_for(
          drb_port:     URI.parse( Hoodoo::Services::Discovery::ByDRb::DRbServer.uri() ).port,
          auto_session: false
        )
      end

      it_behaves_like Hoodoo::Client
    end

    context 'and by DRb with custom discoverer' do
      before :each do
        drb_port   = URI.parse( Hoodoo::Services::Discovery::ByDRb::DRbServer.uri() ).port
        discoverer = Hoodoo::Services::Discovery::ByDRb.new( drb_port: drb_port )

        expect( discoverer ).to receive( :discover ).at_least( :once ).and_call_original

        set_vars_for(
          drb_port:     drb_port,
          auto_session: false,
          discoverer:   discoverer
        )
      end

      it_behaves_like Hoodoo::Client
    end

    context 'and by convention' do
      before :each do
        set_vars_for(
          base_uri:     "http://localhost:#{ @port }",
          auto_session: false
        )
      end

      it_behaves_like Hoodoo::Client
    end

    context 'and by convention with custom discoverer' do
      before :each do
        base_uri   = "http://localhost:#{ @port }"
        discoverer = Hoodoo::Services::Discovery::ByConvention.new( base_uri: base_uri )

        expect( discoverer ).to receive( :discover ).at_least( :once ).and_call_original

        set_vars_for(
          base_uri:     base_uri,
          auto_session: false,
          session_id:   @old_test_session.session_id,
          discoverer:   discoverer
        )
      end

      it_behaves_like Hoodoo::Client
    end

    context 'and with an HTTP proxy via custom discoverer' do
      before :each do
        base_uri   = "http://localhost:#{ @port }"
        proxy_uri  = 'http://foo:bar@proxyhost:1234'
        discoverer = Hoodoo::Services::Discovery::ByConvention.new(
          base_uri:  base_uri,
          proxy_uri: proxy_uri
        )

        original_new = Net::HTTP.method( :new )

        expect( Net::HTTP ).to receive( :new ).at_least( :once ) do | host, port, proxy_host, proxy_port, proxy_user, proxy_pass |
          expect( host       ).to eq( 'localhost' )
          expect( port       ).to eq( @port       )
          expect( proxy_host ).to eq( 'proxyhost' )
          expect( proxy_port ).to eq( 1234        )
          expect( proxy_user ).to eq( 'foo'       )
          expect( proxy_pass ).to eq( 'bar'       )

          original_new.call( host, port )
        end

        set_vars_for(
          base_uri:     base_uri,
          auto_session: false,
          session_id:   @old_test_session.session_id,
          discoverer:   discoverer
        )
      end

      it_behaves_like Hoodoo::Client
    end
  end

  ##############################################################################
  # No automatic session acquisition with manual session
  ##############################################################################

  context 'with a manual session' do
    shared_examples Hoodoo::Client do
      it 'can contact public actions' do
        mock_ident = Hoodoo::UUID.generate()

        result = @endpoint.show( mock_ident )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
      end

      it 'can contact protected actions' do
        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'bar' ]
        query_hash = { '_embed' => embeds }

        result = @endpoint.list( query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result.dataset_size ).to eq( result.size )
        expect( result[ 0 ][ 'embeds' ] ).to eq( embeds )
        expect( result[ 0 ][ 'language' ] ).to eq( @expected_locale )
        expect( result[ 0 ][ 'dated_at' ] ).to eq( @expected_dated_at )

        embeds     = [ 'baz' ]
        query_hash = { '_embed' => embeds }
        body_hash  = { 'hello' => 'world' }

        result = @endpoint.create( body_hash, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'body_hash' ] ).to eq( body_hash )
        expect( result[ 'embeds' ] ).to eq( embeds )
        expect( result[ 'language' ] ).to eq( @expected_locale )
        expect( result[ 'dated_at' ] ).to eq( @expected_dated_at )

        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'foo' ]
        query_hash = { '_embed' => embeds }
        body_hash  = { 'left' => 'right' }

        result = @endpoint.update( mock_ident, body_hash, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
        expect( result[ 'body_hash' ] ).to eq( body_hash )
        expect( result[ 'embeds' ] ).to eq( embeds )
        expect( result[ 'language' ] ).to eq( @expected_locale )
        expect( result[ 'dated_at' ] ).to eq( @expected_dated_at )

        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'baz', 'bar' ]
        query_hash = { '_embed' => embeds }

        result = @endpoint.delete( mock_ident, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
        expect( result[ 'embeds' ] ).to eq( embeds )
        expect( result[ 'language' ] ).to eq( @expected_locale )
        expect( result[ 'dated_at' ] ).to eq( @expected_dated_at )
      end
    end

    before :each do
      Hoodoo::Services::Middleware.set_test_session( @old_test_session )
    end

    context 'and by DRb' do
      before :each do
        set_vars_for(
          drb_port:     URI.parse( Hoodoo::Services::Discovery::ByDRb::DRbServer.uri() ).port,
          auto_session: false,
          session_id:   @old_test_session.session_id
        )
      end

      it_behaves_like Hoodoo::Client
    end

    context 'and by convention' do
      before :each do
        set_vars_for(
          base_uri:     "http://localhost:#{ @port }",
          auto_session: false,
          session_id:   @old_test_session.session_id
        )
      end

      it_behaves_like Hoodoo::Client
    end
  end

  ##############################################################################
  # Automatic session acquisition
  ##############################################################################

  context 'with auto-session' do
    shared_examples Hoodoo::Client do
      it 'can contact public actions' do
        mock_ident = Hoodoo::UUID.generate()

        result = @endpoint.show( mock_ident )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
      end

      it 'can contact protected actions' do
        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'bar' ]
        query_hash = { '_embed' => embeds }

        result = @endpoint.list( query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result.dataset_size ).to eq( result.size )
        expect( result[ 0 ][ 'embeds' ] ).to eq( embeds )
        expect( result[ 0 ][ 'language' ] ).to eq( @expected_locale )
        expect( result[ 0 ][ 'dated_at' ] ).to eq( @expected_dated_at )

        embeds     = [ 'baz' ]
        query_hash = { '_embed' => embeds }
        body_hash  = { 'hello' => 'world' }

        result = @endpoint.create( body_hash, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'body_hash' ] ).to eq( body_hash )
        expect( result[ 'embeds' ] ).to eq( embeds )
        expect( result[ 'language' ] ).to eq( @expected_locale )
        expect( result[ 'dated_at' ] ).to eq( @expected_dated_at )

        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'foo' ]
        query_hash = { '_embed' => embeds }
        body_hash  = { 'left' => 'right' }

        result = @endpoint.update( mock_ident, body_hash, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
        expect( result[ 'body_hash' ] ).to eq( body_hash )
        expect( result[ 'embeds' ] ).to eq( embeds )
        expect( result[ 'language' ] ).to eq( @expected_locale )
        expect( result[ 'dated_at' ] ).to eq( @expected_dated_at )

        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'baz', 'bar' ]
        query_hash = { '_embed' => embeds }

        result = @endpoint.delete( mock_ident, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
        expect( result[ 'embeds' ] ).to eq( embeds )
        expect( result[ 'language' ] ).to eq( @expected_locale )
        expect( result[ 'dated_at' ] ).to eq( @expected_dated_at )
      end

      it 'automatically retries' do
        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( false )

        expect_any_instance_of( RSpecClientTestSessionImplementation ).to receive( :create ).once.and_call_original
        Hoodoo::Services::Middleware.set_test_session( nil )

        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( false )
      end

      it 'handles errors from the session resource' do
        expect_any_instance_of( RSpecClientTestSessionImplementation ).to receive( :create ).and_raise( "boo!" )

        Hoodoo::Services::Middleware.set_test_session( nil )

        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( true )
        expect( result.platform_errors.errors[ 0 ][ 'code' ] ).to eq( 'platform.fault' )
      end

      it 'handles malformed sessions' do
        expect_any_instance_of( RSpecClientTestSessionImplementation ).to receive( :create ) { | ignored, context |
          context.response.body = { 'not' => 'a session' }
        }

        Hoodoo::Services::Middleware.set_test_session( nil )

        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( true )
        expect( result.platform_errors.errors[ 0 ][ 'code' ] ).to eq( 'generic.malformed' )
      end
    end

    before :each do
      Hoodoo::Services::Middleware.set_test_session( nil )
    end

    context 'and by DRb' do
      before :each do
        set_vars_for(
          drb_port:              URI.parse( Hoodoo::Services::Discovery::ByDRb::DRbServer.uri() ).port,
          caller_id:             Hoodoo::UUID.generate,
          caller_secret:         Hoodoo::UUID.generate,
          auto_session_resource: 'RSpecClientTestSession'
        )
      end

      it_behaves_like Hoodoo::Client
    end

    context 'and by convention' do
      before :each do
        set_vars_for(
          base_uri:              "http://localhost:#{ @port }",
          caller_id:             Hoodoo::UUID.generate,
          caller_secret:         Hoodoo::UUID.generate,
          auto_session_resource: 'RSpecClientTestSession'
        )
      end

      it_behaves_like Hoodoo::Client
    end
  end

  ##############################################################################
  # Code coverage
  ##############################################################################

  context 'code coverage' do
    it 'complains about missing options in the constructor' do
      expect {
        Hoodoo::Client.new
      }.to raise_error( RuntimeError, 'Hoodoo::Client: Please pass one of the "base_uri", "drb_uri" or "drb_port" parameters.' )
    end
  end
end
