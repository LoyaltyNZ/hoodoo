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
      'created_at' => Hoodoo::Utilities.standard_datetime( Time.now ),
      'kind'       => 'RSpecClientTestSession',
      'caller_id'  => context.request.body[ 'caller_id' ],
      'expires_at' => Hoodoo::Utilities.standard_datetime( Time.now + 24 * 60 * 60 )
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

      # Deliberate error generation hook.
      #
      if context.request.ident == 'return_error'
        context.response.add_error( 'platform.malformed' )
        return
      end

      context.response.set_resource( mock( context ) )
    end

    # The rest will be protected actions

    def list( context )

      # Deliberate error generation hook.
      #
      if context.request.list.offset == 42
        context.response.add_error( 'platform.malformed' )
        return
      end

      resources = [ mock( context ), mock( context ), mock( context ) ]

      if context.request.embeds.include?( 'estimated_counts_please' )
        context.response.set_estimated_resources( resources, resources.count )
      else
        context.response.set_resources( resources, resources.count )
      end
    end

    def create( context )

      # Deliberate error generation hook.
      #
      if context.request.body.has_key?( 'return_error' )
        context.response.add_error( 'platform.malformed' )
        return
      end

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

      # Deliberate error generation hook.
      #
      if context.request.ident == 'return_error'
        context.response.add_error( 'platform.malformed' )
        return
      end

      context.response.set_resource( mock( context ) )
      context.response.add_header( 'X-Example-Header', 'example' )
    end

    def delete( context )

      # Deliberate error generation hook.
      #
      if context.request.ident == 'return_error'
        context.response.add_error( 'platform.malformed' )
        return
      end

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
        'id'                 => context.request.ident                 ||
                                context.request.body.try( :[], 'id' ) ||
                                Hoodoo::UUID.generate(),

        'created_at'         => Hoodoo::Utilities.standard_datetime( Time.now ),
        'kind'               => 'RSpecClientTestTarget',
        'language'           => context.request.locale,

        'embeds'             => context.request.embeds,
        'body_hash'          => context.request.body,
        'dated_at'           => context.request.dated_at.nil?   ? nil : Hoodoo::Utilities.nanosecond_iso8601( context.request.dated_at   ),
        'dated_from'         => context.request.dated_from.nil? ? nil : Hoodoo::Utilities.nanosecond_iso8601( context.request.dated_from ),
        'resource_uuid'      => context.request.resource_uuid,
        'deja_vu'            => context.request.deja_vu,
        'assume_identity_of' => context.request.assume_identity_of,
        'actual_identity'    => ( context.session.identity.to_h rescue nil ),
      }
    end
end

class RSpecClientTestTargetInterface < Hoodoo::Services::Interface
  interface :RSpecClientTestTarget do
    endpoint :r_spec_client_test_targets, RSpecClientTestTargetImplementation
    public_actions :show
    actions :list, :create, :update, :delete
    embeds :foo, :bar, :baz, :estimated_counts_please
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

  before :each do
    spec_helper_use_mock_memcached()
  end

  before :all do
    @old_test_session = Hoodoo::Services::Middleware.test_session()
    @port = spec_helper_start_svc_app_in_thread_for( RSpecClientTestService )
    @https_port = spec_helper_start_svc_app_in_thread_for( RSpecClientTestService, true )
    @authorised_identities = { 'member_id' => [ '23', '24' ] }
    @example_authorised_identity = { 'member_id' => '23' }
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
    @locale          = rand( 2 ) == 0 ? nil : SecureRandom.urlsafe_base64(2)
    @expected_locale = @locale.nil? ? 'en-nz' : @locale.downcase
    @client          = Hoodoo::Client.new( opts.merge( :locale => @locale ) )

    endpoint_opts = {}

    # Part of this could be automatic via HEADER_TO_PROPERTY but then
    # any errors in that mapping which don't match our requirements in
    # the test would be hidden, by the test using the same broken map.
    #
    # See also "def mock" earlier in this file and
    # "def option_based_expectations" later in this file. Be careful
    # to follow the naming convention evident below if adding things.

    @expected_dated_at           = @dated_at.nil?   ? nil : Hoodoo::Utilities.nanosecond_iso8601( @dated_at   )
    @expected_dated_from         = @dated_from.nil? ? nil : Hoodoo::Utilities.nanosecond_iso8601( @dated_from )
    @expected_resource_uuid      = @resource_uuid
    @expected_assume_identity_of = @assume_identity_of
    @expected_deja_vu            = @deja_vu != true ? nil : true

    endpoint_opts[ :dated_at           ] = @dated_at           unless @dated_at.nil?
    endpoint_opts[ :dated_from         ] = @dated_from         unless @dated_from.nil?
    endpoint_opts[ :resource_uuid      ] = @resource_uuid      unless @resource_uuid.nil?
    endpoint_opts[ :assume_identity_of ] = @assume_identity_of unless @assume_identity_of.nil?
    endpoint_opts[ :deja_vu            ] = @deja_vu            if     @deja_vu == true

    if rand( 2 ) == 0
      override_locale          = SecureRandom.urlsafe_base64( 2 )
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

    if result.is_a?( Hoodoo::Client::AugmentedArray )
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

    context 'and with a custom HTTP read timeout' do
      before :each do
        timeout    = 0.001
        base_uri   = "http://localhost:#{ @port }"
        discoverer = Hoodoo::Services::Discovery::ByConvention.new(
          base_uri:     base_uri,
          http_timeout: timeout
        )

        set_vars_for(
          base_uri:     base_uri,
          auto_session: false,
          session_id:   @old_test_session.session_id,
          discoverer:   discoverer
        )

        expect_any_instance_of( Net::HTTP ).to receive( :read_timeout= ).with( timeout ).and_call_original
        allow_any_instance_of( Net::BufferedIO ).to receive( :read ) do | instance, *args |
          expect( instance.read_timeout ).to eq( timeout )
          raise Net::ReadTimeout
        end
      end

      it 'times out elegantly' do
        mock_ident = Hoodoo::UUID.generate()
        result     = @endpoint.show( mock_ident )

        expect( result.platform_errors.has_errors? ).to eq( true )
        expect( result.platform_errors.errors[ 0 ][ 'code' ] ).to eq( 'platform.timeout' )
      end
    end

    context 'and with a custom HTTP open timeout' do
      before :each do
        timeout    = 0.001
        base_uri   = "http://localhost:#{ @port }"
        discoverer = Hoodoo::Services::Discovery::ByConvention.new(
          base_uri:          base_uri,
          http_open_timeout: timeout
        )

        set_vars_for(
          base_uri:     base_uri,
          auto_session: false,
          session_id:   @old_test_session.session_id,
          discoverer:   discoverer
        )

        expect( Timeout ).to receive( :timeout ).with( timeout, Net::OpenTimeout ).once do
          raise Net::OpenTimeout
        end
      end

      it 'times out elegantly' do
        mock_ident = Hoodoo::UUID.generate()
        result     = @endpoint.show( mock_ident )

        expect( result.platform_errors.has_errors? ).to eq( true )
        expect( result.platform_errors.errors[ 0 ][ 'code' ] ).to eq( 'platform.timeout' )
      end
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
            when :assume_identity_of
              @assume_identity_of = @example_authorised_identity
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
        expect( result.estimated_dataset_size ).to be_nil

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

      it "provides estimations" do
        query_hash = { '_embed' => 'estimated_counts_please' }

        result = @endpoint.list( query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result.dataset_size ).to be_nil
        expect( result.estimated_dataset_size ).to eq( result.size )

        expect( result[ 0 ][ 'language' ] ).to eq( @expected_locale )

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

    context 'and when endpoints return errors' do
      before :each do
        set_vars_for(
          base_uri:     "http://localhost:#{ @port }",
          auto_session: false,
          session_id:   @old_test_session.session_id
        )
      end

      it 'returns an AugmentedArray for #list' do
        result = @endpoint.list( { :offset => 42 } ) # 42 -> magic -> service adds error

        expect( result ).to be_a( Hoodoo::Client::AugmentedArray )
        expect( result.platform_errors.has_errors? ).to eq( true )
      end

      it 'returns an AugmentedHash for #show' do
        result = @endpoint.show( 'return_error' )

        expect( result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( result.platform_errors.has_errors? ).to eq( true )
      end

      it 'returns an AugmentedHash for #create' do
        result = @endpoint.create( { 'return_error' => true } )

        expect( result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( result.platform_errors.has_errors? ).to eq( true )
      end

      it 'returns an AugmentedHash for #update' do
        result = @endpoint.update( 'return_error', {} )

        expect( result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( result.platform_errors.has_errors? ).to eq( true )
      end

      it 'returns an AugmentedHash for #delete' do
        result = @endpoint.delete( 'return_error' )

        expect( result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( result.platform_errors.has_errors? ).to eq( true )
      end
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
        test_session.identity = OpenStruct.new
        test_session.scoping = @old_test_session.scoping.dup
        test_session.scoping.authorised_http_headers = []
        test_session.scoping.authorised_identities = @authorised_identities

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
            when :assume_identity_of
              @assume_identity_of = @example_authorised_identity
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

          option_based_expectations( result )
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

      context "'assume_identity_of' in use" do
        it 'but invalid' do
          @assume_identity_of = { 'invalid' => 'Hoodoo::UUID.generate' }

          set_vars_for(
            base_uri:     "http://localhost:#{ @port }",
            auto_session: false
          )

          result = @endpoint.create( { 'hello' => 'world' } )

          expect( result.platform_errors.has_errors? ).to eq( true )
          expect( result.platform_errors.errors[ 0 ][ 'code' ] ).to eq( 'platform.forbidden' )
        end

        it 'and valid' do
          @assume_identity_of = @example_authorised_identity

          set_vars_for(
            base_uri:     "http://localhost:#{ @port }",
            auto_session: false
          )

          result = @endpoint.create( { 'hello' => 'world' } )

          expect( result.platform_errors.has_errors? ).to eq( false )
          expect( result[ 'actual_identity' ] ).to eq( @example_authorised_identity )
        end
      end
    end
  end

  ##############################################################################
  # Automatic session acquisition
  ##############################################################################

  context 'with auto-session' do
    before :each do
      Hoodoo::Services::Middleware.set_test_session( nil )
    end

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
        expect( result.estimated_dataset_size ).to be_nil

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

      it "provides estimations" do
        query_hash = { '_embed' => 'estimated_counts_please' }

        result = @endpoint.list( query_hash )
        expect( result.platform_errors.has_errors? ).to eq( false )
        expect( result.dataset_size ).to be_nil
        expect( result.estimated_dataset_size ).to eq( result.size )

        expect( result[ 0 ][ 'language' ] ).to eq( @expected_locale )

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

      it 'automatically retries with more than just "platform.invalid_session" present' do

        # When we list first, Client has no session so will acquire one. The
        # wrapping endpoint is asked to list, it pushes that through the
        # session mechanism, gets the session and then calls the wrapped
        # endpoint.

        expect( @endpoint ).to receive( :acquire_session_for ).once.with( :list ).and_call_original
        expect( @endpoint.instance_variable_get( '@wrapped_endpoint' ) ).to receive( :list ).once.and_call_original

        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( false )

        # When we list the second time, the wrapping endpoint has a session
        # but we fake a complex 'invalid session' response from the wrapped
        # endpoint, as if the session had (say) expired at the server end,
        # but other errors were being reported too.

        expect( @endpoint.instance_variable_get( '@wrapped_endpoint' ) ).to receive( :list ).once do
          array = Hoodoo::Client::AugmentedArray.new
          array.platform_errors.add_error( 'platform.forbidden' )
          array.platform_errors.add_error( 'platform.invalid_session' )
          array.platform_errors.add_error( 'platform.method_not_allowed' )
          array
        end

        # This means we expect another session acquisition attempt, which is
        # allowed to succeed, then the wrapped endpoint should be called.

        expect( @endpoint ).to receive( :acquire_session_for ).once.with( :list ).and_call_original
        expect( @endpoint.instance_variable_get( '@wrapped_endpoint' ) ).to receive( :list ).once.and_call_original

        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( false )
      end

      it 'does not retry for errors other than "platform.invalid_session"' do

        # When we list first, Client has no session so will acquire one. The
        # wrapping endpoint is asked to list, it pushes that through the
        # session mechanism, gets the session and then calls the wrapped
        # endpoint.

        expect( @endpoint ).to receive( :acquire_session_for ).once.with( :list ).and_call_original
        expect( @endpoint.instance_variable_get( '@wrapped_endpoint' ) ).to receive( :list ).once.and_call_original

        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( false )

        # When we list the second time, the wrapping endpoint has a session
        # but we fake a simple "generic.malformed" response from the wrapped
        # endpoint (probably impossible from a 'list' call in reality, but
        # just some easy error that we can check for afterwards and is not as
        # likely to be generated incidentally from other pieces of code as
        # e.g. "generic.invalid_parameters").

        expect( @endpoint.instance_variable_get( '@wrapped_endpoint' ) ).to receive( :list ).once do
          array = Hoodoo::Client::AugmentedArray.new
          array.platform_errors.add_error( 'generic.malformed' )
          array
        end

        # This is just a normal error; we do not expect another session
        # acquisition attempt or a retried call to #list.

        expect( @endpoint ).to_not receive( :acquire_session_for )
        expect( @endpoint.instance_variable_get( '@wrapped_endpoint' ) ).to_not receive( :list )

        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( true )
        expect( result.platform_errors.errors[ 0 ][ 'code' ] ).to eq( 'generic.malformed' )
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

      it 'handles malformed sessions when retrying' do
        result = @endpoint.list()
        expect( result.platform_errors.has_errors? ).to eq( false )

        Hoodoo::Services::Middleware.set_test_session( nil )

        expect_any_instance_of( RSpecClientTestSessionImplementation ).to receive( :create ) { | ignored, context |
          context.response.body = { 'not' => 'a session' }
        }

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
      }.to raise_error( RuntimeError, 'Hoodoo::Client: Please pass one of the "discoverer", "base_uri", "drb_uri" or "drb_port" parameters.' )
    end

    context 'with ActiveSupport absent' do
      before :all do
        @old_discoverer = Hoodoo::Services::Discovery::ByConvention
        Hoodoo::Services::Discovery.send( :remove_const, :ByConvention )
      end

      it 'lead to a useful exception if the ByDiscovery discoverer is requested' do
        expect {
          Hoodoo::Client.new( base_uri: 'http://localhost' )
        }.to raise_error( RuntimeError, 'Hoodoo::Client: The constructor parameters indicate the use of a "by convention" discoverer. This discoverer requires ActiveSupport; ensure the ActiveSupport gem is present and "require"-able.' )
      end

      after :all do
        Hoodoo::Services::Discovery.send( :const_set, :ByConvention, @old_discoverer )
      end
    end
  end
end
