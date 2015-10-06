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

      # If expecting deja-vu, cause deja-vu.
      #
      if context.request.deja_vu
        context.response.add_error(
          'generic.invalid_duplication',
          :reference => { :field_name => 'hello' }
        )

      else
        context.response.set_resource( mock( context ) )

      end
    end

    def update( context )
      context.response.set_resource( mock( context ) )
      context.response.add_header( 'X-Example-Header', 'example' )
    end

    def delete( context )
      context.response.set_resource( mock( context ) )
    end

  private
    def mock( context )

      # Part of this could be automatic via HEADER_TO_PROPERTY but then
      # any errors in that mapping which don't match our requirements in
      # the test would be hidden, by the test using the same broken map.
      #
      # See also "def set_vars_for" and "def option_based_expectations"
      # below. Be careful to follow the naming convention evident below
      # if adding things.

      {
        'id'            => context.request.ident                 ||
                           context.request.body.try( :[], 'id' ) ||
                           Hoodoo::UUID.generate(),

        'created_at'    => Time.now.utc.iso8601,
        'kind'          => 'RSpecClientTestTarget',
        'language'      => context.request.locale,

        'embeds'        => context.request.embeds,
        'body_hash'     => context.request.body,
        'dated_at'      => context.request.dated_at.nil?   ? nil : Hoodoo::Utilities.nanosecond_iso8601( context.request.dated_at   ),
        'dated_from'    => context.request.dated_from.nil? ? nil : Hoodoo::Utilities.nanosecond_iso8601( context.request.dated_from ),
        'resource_uuid' => context.request.resource_uuid,
        'deja_vu'       => context.request.deja_vu,
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

# This resource is just here for the custom routing tests.
#
class RSpecClientTestTargetCustomRoutingImplementation < Hoodoo::Services::Implementation
  def show( context )
    context.response.set_resource( { 'id' => context.request.ident } )
  end
end

class RSpecClientTestTargetCustomRoutingInterface < Hoodoo::Services::Interface
  interface :RSpecClientTestTargetCustomRouting do
    endpoint :r_spec_client_test_targets_with_custom_route, RSpecClientTestTargetCustomRoutingImplementation
    public_actions :show
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
               RSpecClientTestTargetInterface,
               RSpecClientTestTargetCustomRoutingInterface
end

##############################################################################
# Tests
##############################################################################

describe Hoodoo::Client do

  before :all do
    @old_test_session = Hoodoo::Services::Middleware.test_session()
    @port = spec_helper_start_svc_app_in_thread_for( RSpecClientTestService )
    @https_port = spec_helper_start_svc_app_in_thread_for( RSpecClientTestService, true )
  end

  after :all do
    Hoodoo::Services::Middleware.set_test_session( @old_test_session )
  end

  # Set @locale, @expected_locale (latter for 'to eq(...)' matching),
  # @dated_at/from, @expected_data_at/from (same deal), @client and callable
  # @endpoint up, passing the given options to the Hoodoo::Client constructor,
  # with randomised locale merged in. Conversion to lower case is checked
  # implicitly, with a mixed case locale generated (potentially) by random
  # but the 'downcase' version being used for 'expect's.
  #
  # Similar instance variables are used for UUID and déjà-vu specifiers. This
  # method will probably get expanded over time with other properties derived
  # from Hoodoo::Client::Headers' HEADER_TO_PROPERTY map too.
  #
  # Through the use of random switches, we (eventually!) get test coverage
  # on locale specified (or not) given to the Client, plus override locale
  # (or not) and a dated-at date/time (or not) given to the Endpoint.
  #
  def set_vars_for( opts )
    @locale              = rand( 2 ) == 0 ? nil : SecureRandom.urlsafe_base64(2)
    @expected_locale     = @locale.nil? ? 'en-nz' : @locale.downcase
    @client              = Hoodoo::Client.new( opts.merge( :locale => @locale ) )

    endpoint_opts = {}

    # Part of this could be automatic via HEADER_TO_PROPERTY but then
    # any errors in that mapping which don't match our requirements in
    # the test would be hidden, by the test using the same broken map.
    #
    # See also "def mock" earlier in this file and
    # "def option_based_expectations" later in this file. Be careful
    # to follow the naming convention evident below if adding things.

    @expected_dated_at      = @dated_at.nil?   ? nil : Hoodoo::Utilities.nanosecond_iso8601( @dated_at   )
    @expected_dated_from    = @dated_from.nil? ? nil : Hoodoo::Utilities.nanosecond_iso8601( @dated_from )
    @expected_resource_uuid = @resource_uuid
    @expected_deja_vu       = @deja_vu != true ? nil : true

    endpoint_opts[ :dated_at      ] = @dated_at      unless @dated_at.nil?
    endpoint_opts[ :dated_from    ] = @dated_from    unless @dated_from.nil?
    endpoint_opts[ :resource_uuid ] = @resource_uuid unless @resource_uuid.nil?
    endpoint_opts[ :deja_vu       ] = @deja_vu       if     @deja_vu == true

    if rand( 2 ) == 0
      override_locale          = SecureRandom.urlsafe_base64(2)
      endpoint_opts[ :locale ] = override_locale
      @expected_locale         = override_locale.downcase
    end

    @endpoint = @client.resource( :RSpecClientTestTarget, 1, endpoint_opts )
  end

  # Automatic expectations based on HEADER_TO_PROPERTY are fine here as they
  # are just working off the properties and the associated variable naming
  # conventions within this test file.
  #
  # See also "def mock" and "def set_vars_for" earlier in this file.
  #
  def option_based_expectations( result )

    if ( result.class < Array )
      resource = result[ 0 ]
    else
      resource = result
    end

    Hoodoo::Client::Headers::HEADER_TO_PROPERTY.each do | rack_header, description |
      property = description[ :property ]
      expect( resource[ property.to_s ] ).to eq( instance_variable_get( "@expected_#{ property }" ) )
    end

    # We also always expect some standard response headers to have been included
    # in the result out-of-band options payload.

    expect( result.response_options[ 'interaction_id' ] ).to be_present
    expect( Hoodoo::UUID.valid?( result.response_options[ 'interaction_id' ] ) ).to eq( true )
    expect( result.response_options[ 'service_response_time' ] ).to be_present

  end

  ##############################################################################
  # No automatic session acquisition and no session
  ##############################################################################

  context 'without any session' do
    shared_examples Hoodoo::Client do
      it '(public actions allowed)' do
        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'foo', 'baz' ]
        query_hash = { '_embed' => embeds }

        result = @endpoint.show( mock_ident )
        expect( result.platform_errors.has_errors? ).to eq( false )

        expect( result[ 'id'       ] ).to eq( mock_ident )
        expect( result[ 'embeds'   ] ).to eq( [] )
        expect( result[ 'language' ] ).to eq( @expected_locale )

        option_based_expectations( result )

        result = @endpoint.show( mock_ident, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )

        expect( result[ 'id'       ] ).to eq( mock_ident )
        expect( result[ 'embeds'   ] ).to eq( embeds )
        expect( result[ 'language' ] ).to eq( @expected_locale )

        option_based_expectations( result )
      end

      it '(protected actions prohibited)' do
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

    context 'and with a custom ca_file' do
      before :each do
        # Note: the ssl-cert is for 127.0.0.1, localhost doesn't match it
        base_uri   = "https://127.0.0.1:#{ @https_port }"
        ca_file    = 'spec/files/ca/ca-cert.pem'
        discoverer = Hoodoo::Services::Discovery::ByConvention.new(
          base_uri:  base_uri,
          ca_file:   ca_file
        )

        set_vars_for(
          base_uri:     base_uri,
          auto_session: false,
          session_id:   @old_test_session.session_id,
          discoverer:   discoverer
        )
      end

      it_behaves_like Hoodoo::Client
    end

    context 'and with custom routing' do
      it 'obeys the routes' do
        base_uri   = "http://localhost:#{ @port }"
        discoverer = Hoodoo::Services::Discovery::ByConvention.new(
          :base_uri => base_uri,
          :routing  => {
            :RSpecClientTestTargetCustomRouting => {
              1 => '/v1/r_spec_client_test_targets_with_custom_route'
            }
          }
        )

        set_vars_for(
          base_uri:     base_uri,
          auto_session: false,
          session_id:   @old_test_session.session_id,
          discoverer:   discoverer
        )

        mock_ident = Hoodoo::UUID.generate()
        result     = @client.resource( :RSpecClientTestTargetCustomRouting, 1 ).show( mock_ident )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
      end
    end

    context 'rejects a request with secured option' do
      Hoodoo::Client::Headers::HEADER_TO_PROPERTY.each do | rack_header, description |
        property = description[ :property ]
        secured  = description[ :secured  ]

        next unless secured == true

        it "'#{ property }' present" do
          case property
            when :resource_uuid
              @resource_uuid = Hoodoo::UUID.generate
            else
              raise "Update client_spec.rb with new secured properties for test"
          end

          set_vars_for(
            base_uri:     "http://localhost:#{ @port }",
            auto_session: false
          )

          mock_ident = Hoodoo::UUID.generate()
          result     = @endpoint.show( mock_ident )

          expect( result.platform_errors.has_errors? ).to eq( true )
          expect( result.platform_errors.errors[ 0 ][ 'code' ] ).to eq( 'platform.forbidden' )
        end
      end
    end

    context 'accepts a request with non-secured option' do
      Hoodoo::Client::Headers::HEADER_TO_PROPERTY.each do | rack_header, description |
        property = description[ :property ]
        secured  = description[ :secured  ]

        next if secured == true

        context "'#{ property }' present" do
          before :each do
            case property
              when :dated_at
                @dated_at = Time.now - 1.year
              when :dated_from
                @dated_from = Time.now - 2.years
              when :deja_vu
                @deja_vu = true
              else
                raise "Update client_spec.rb with new non-secured properties for test"
            end

            set_vars_for(
              base_uri:     "http://localhost:#{ @port }",
              auto_session: false
            )
          end

          it_behaves_like Hoodoo::Client
        end
      end
    end
  end

  ##############################################################################
  # No automatic session acquisition with manual session
  ##############################################################################

  context 'with a manual session' do
    shared_examples Hoodoo::Client do
      it '(public actions allowed)' do
        mock_ident = Hoodoo::UUID.generate()

        result = @endpoint.show( mock_ident )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
      end

      it '(protected actions prohibited)' do
        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'bar' ]
        query_hash = { '_embed' => embeds }

        result = @endpoint.list( query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result.dataset_size ).to eq( result.size )

        expect( result[ 0 ][ 'embeds'   ] ).to eq( embeds )
        expect( result[ 0 ][ 'language' ] ).to eq( @expected_locale )

        option_based_expectations( result )

        embeds     = [ 'baz' ]
        query_hash = { '_embed' => embeds }
        body_hash  = { 'hello' => 'world' }

        result = @endpoint.create( body_hash, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )

        expect( result[ 'body_hash' ] ).to eq( body_hash )
        expect( result[ 'embeds'    ] ).to eq( embeds )
        expect( result[ 'language'  ] ).to eq( @expected_locale )

        option_based_expectations( result )

        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'foo' ]
        query_hash = { '_embed' => embeds }
        body_hash  = { 'left' => 'right' }

        result = @endpoint.update( mock_ident, body_hash, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result.response_options[ 'example_header' ] ).to eq( 'example' )

        expect( result[ 'id'        ] ).to eq( mock_ident )
        expect( result[ 'body_hash' ] ).to eq( body_hash )
        expect( result[ 'embeds'    ] ).to eq( embeds )
        expect( result[ 'language'  ] ).to eq( @expected_locale )

        option_based_expectations( result )

        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'baz', 'bar' ]
        query_hash = { '_embed' => embeds }

        result = @endpoint.delete( mock_ident, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )

        expect( result[ 'id'       ] ).to eq( mock_ident )
        expect( result[ 'embeds'   ] ).to eq( embeds )
        expect( result[ 'language' ] ).to eq( @expected_locale )

        option_based_expectations( result )
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

    context 'and with non-secured option' do

      # Specific functional tests

      it "'deja_vu' in use" do
        @deja_vu = true

        set_vars_for(
          base_uri:     "http://localhost:#{ @port }",
          auto_session: false
        )

        result = @endpoint.create( { 'hello' => 'world' } )

        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result.response_options[ 'deja_vu' ] ).to eq( 'confirmed' )
      end
    end

    context 'and with secured option' do
      before :each do
        test_session = @old_test_session.dup
        test_session.scoping = @old_test_session.scoping.dup
        test_session.scoping.authorised_http_headers = []

        Hoodoo::Client::Headers::HEADER_TO_PROPERTY.each do | rack_header, description |
          next unless description[ :secured ] == true
          test_session.scoping.authorised_http_headers << rack_header
        end

        Hoodoo::Services::Middleware.set_test_session( test_session )
      end

      after :each do
        Hoodoo::Services::Middleware.set_test_session( @old_test_session )
      end

      Hoodoo::Client::Headers::HEADER_TO_PROPERTY.each do | rack_header, description |
        property = description[ :property ]
        secured  = description[ :secured  ]

        next unless secured == true

        it "'#{ property }' present" do
          case property
            when :resource_uuid
              @resource_uuid = Hoodoo::UUID.generate
            else
              raise "Update client_spec.rb with new secured properties for test"
          end

          set_vars_for(
            base_uri:     "http://localhost:#{ @port }",
            auto_session: false
          )

          mock_ident = Hoodoo::UUID.generate()
          result     = @endpoint.show( mock_ident )

          expect( result.platform_errors.has_errors? ).to eq( false )
        end
      end

      # Specific functional tests

      it "'resource_uuid' in use" do
        @resource_uuid = Hoodoo::UUID.generate

        set_vars_for(
          base_uri:     "http://localhost:#{ @port }",
          auto_session: false
        )

        result = @endpoint.create( { 'hello' => 'world' } )

        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( @resource_uuid )
      end
    end
  end

  ##############################################################################
  # Automatic session acquisition
  ##############################################################################

  context 'with auto-session' do
    shared_examples Hoodoo::Client do
      it '(public actions allowed)' do
        mock_ident = Hoodoo::UUID.generate()

        result = @endpoint.show( mock_ident )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result[ 'id' ] ).to eq( mock_ident )
      end

      it '(protected actions allowed)' do
        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'bar' ]
        query_hash = { '_embed' => embeds }

        result = @endpoint.list( query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result.dataset_size ).to eq( result.size )

        expect( result[ 0 ][ 'embeds'   ] ).to eq( embeds )
        expect( result[ 0 ][ 'language' ] ).to eq( @expected_locale )

        option_based_expectations( result )

        embeds     = [ 'baz' ]
        query_hash = { '_embed' => embeds }
        body_hash  = { 'hello' => 'world' }

        result = @endpoint.create( body_hash, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )

        expect( result[ 'body_hash' ] ).to eq( body_hash )
        expect( result[ 'embeds'    ] ).to eq( embeds )
        expect( result[ 'language'  ] ).to eq( @expected_locale )

        option_based_expectations( result )

        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'foo' ]
        query_hash = { '_embed' => embeds }
        body_hash  = { 'left' => 'right' }

        result = @endpoint.update( mock_ident, body_hash, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result.response_options[ 'example_header' ] ).to eq( 'example' )

        expect( result[ 'id'        ] ).to eq( mock_ident )
        expect( result[ 'body_hash' ] ).to eq( body_hash )
        expect( result[ 'embeds'    ] ).to eq( embeds )
        expect( result[ 'language'  ] ).to eq( @expected_locale )

        option_based_expectations( result )

        mock_ident = Hoodoo::UUID.generate()
        embeds     = [ 'baz', 'bar' ]
        query_hash = { '_embed' => embeds }

        result = @endpoint.delete( mock_ident, query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )

        expect( result[ 'id'       ] ).to eq( mock_ident )
        expect( result[ 'embeds'   ] ).to eq( embeds )
        expect( result[ 'language' ] ).to eq( @expected_locale )

        option_based_expectations( result )
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

      # This is a fragile test due to the way it is forced to simulate a
      # connection fault; see similar test in middleware_multi_spec.rb
      # for details.
      #
      it 'handles explicit connection errors as 404' do
        expect_any_instance_of( Net::HTTP ).to receive( :request ).once.and_raise( Errno::ECONNREFUSED )
        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( true )
        expect( result.platform_errors.errors[ 0 ][ 'code' ] ).to eq( 'platform.not_found' )
      end

      # As above, this is a fragile test.
      #
      it 'handles arbitrary communication errors as 500' do
        expect_any_instance_of( Net::HTTP ).to receive( :request ).once.and_raise( 'some connection error' )
        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( true )
        expect( result.platform_errors.errors[ 0 ][ 'code' ] ).to eq( 'platform.fault' )
        expect( result.platform_errors.errors[ 0 ][ 'reference' ] ).to include( 'some connection error' )
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
