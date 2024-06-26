###############################################################################
# Remote inter-resource calls
#
# Start multiple HTTP server instances in threads and have them talk to each
# other in order to test remote inter-resource calls.
###############################################################################

require 'spec_helper'
require 'json'

# Used for X-Assume-Identity-Of testing to avoid magic value copy-and-paste.
#
MMRS_CUSTOM_CALLER_ID            = 'custom_caller_id'
MMRS_VALID_ASSUMED_IDENTITY_HASH = { 'caller_id' => MMRS_CUSTOM_CALLER_ID }

# First, a test service comprised of a couple of 'echo' variants which we use
# to make sure they're both correctly stored in the DRb registry.
#
class TestEchoImplementation < Hoodoo::Services::Implementation

  public

    def list( context )

      # Deliberate error generation hook.
      #
      if context.request.list.offset == 42
        context.response.add_error( 'platform.malformed' )
        return
      end

      array =
      [
        { 'list0' => TestEchoImplementation.to_h( context ) },
        { 'list1' => TestEchoImplementation.to_h( context ) },
        { 'list2' => TestEchoImplementation.to_h( context ) }
      ]

      context.response.set_resources( array, 49 )
      context.response.set_estimated_resources( array, 50 )
    end

    def show( context )
      if context.request.uri_path_components[ 0 ] == 'return_error'
        context.response.add_error(
          'generic.invalid_string',
          :message => 'Returning error as requested',
          :reference => { :another => 'no other ident', :field_name => 'no ident' }
        )
      elsif context.request.uri_path_components[ 0 ] == 'return_invalid_data'
        context.response.body = 'Hello, world'
      elsif context.request.ident == 'return_identity' || context.request.ident == 'set_good_inter_resource_identity'
        context.response.body = {
          'identity'    => context.session.identity.to_h,
          'fingerprint' => context.session.caller_fingerprint
        }
      else
        context.response.body = { 'show' => TestEchoImplementation.to_h( context ) }
      end
    end

    def create( context )

      # Deliberate error generation hook.
      #
      if context.request.body.has_key?( 'return_error' )
        context.response.add_error( 'platform.malformed' )
        return
      end

      # If asked to add another error to the response, we're testing
      # the deja-vu stuff including making sure that errors are still returned
      # if any non-"invalid duplication" stuff exists. As long as the error
      # code requires no reference data or only requires a "field_name", this
      # will work OK.
      #
      if context.request.deja_vu
        additional_error_code = context.request.body[ 'additional_error' ] || 'generic.invalid_duplication'
        reference             = { :reference => { :field_name => 'deja_vu' } }

        context.response.add_error( 'generic.invalid_duplication', reference )
        context.response.add_error( additional_error_code,         reference )

        return
      end

      context.response.set_resource( { 'create' => TestEchoImplementation.to_h( context ) } )
    end

    def update( context )

      # Deliberate error generation hook.
      #
      if context.request.ident == 'return_error'
        context.response.add_error( 'platform.malformed' )
        return
      end

      context.response.add_header( 'X-Example-Header', 'example' )
      context.response.body = { 'update' => TestEchoImplementation.to_h( context ) }
    end

    def delete( context )
      return context.response.not_found( context.request.ident ) if context.request.ident == 'simulate_404'
      context.response.body = { 'delete' => TestEchoImplementation.to_h( context ) }
    end

    # Used by both this class and later code in this file.
    #
    def self.to_h( context )
      {
        'locale'              => context.request.locale,
        'dated_at'            => context.request.dated_at.to_s,
        'dated_from'          => context.request.dated_from.to_s,
        'deja_vu'             => context.request.deja_vu.to_s,
        'resource_uuid'       => context.request.resource_uuid.to_s,
        'body'                => context.request.body,
        'uri_path_components' => context.request.uri_path_components,
        'uri_path_extension'  => context.request.uri_path_extension,
        'list_offset'         => context.request.list.offset,
        'list_limit'          => context.request.list.limit,
        'list_sort_data'      => context.request.list.sort_data,
        'list_search_data'    => context.request.list.search_data,
        'list_filter_data'    => context.request.list.filter_data,
        'embeds'              => context.request.embeds,
        'references'          => context.request.references,
        'session_hash'        => context.session.to_h
      }
    end
end

class TestEchoInterface < Hoodoo::Services::Interface
  interface :TestEcho do
    version 2
    endpoint :test_some_echoes, TestEchoImplementation

    embeds :embed_one, :embed_two

    to_list do
      search :search_one, :search_two
      filter :filter_one, :filter_two
    end
  end
end

class TestEchoQuietImplementation < Hoodoo::Services::Implementation

  public

    def show( context )
      context.response.body = { 'show' => TestEchoImplementation.to_h( context ) }
    end

    def list( context )
      expectable_hook( context )
      context.response.set_resources( [ context.request.headers ], 1 )
    end

  private

    def expectable_hook( context )
    end
end

class TestEchoQuietInterface < Hoodoo::Services::Interface
  interface :TestEchoQuiet do
    endpoint :test_echo_quiet, TestEchoQuietImplementation
    actions :show, :list
  end
end

class TestEchoService < Hoodoo::Services::Service
  comprised_of TestEchoInterface, TestEchoQuietInterface
end

# Now the calling service that'll call over to the echo services above.

class TestCallImplementation < Hoodoo::Services::Implementation
  def list( context )
    resource = context.resource( :TestEcho, 2 )
    result   = resource.list(
      {
        'offset'     => context.request.list.offset,
        'limit'      => context.request.list.limit,
        'sort'       => context.request.list.sort_data.keys.first,
        'direction'  => context.request.list.sort_data.values.first,
        'search'     => context.request.list.search_data,
        'filter'     => context.request.list.filter_data,
        '_embed'     => context.request.embeds,
        '_reference' => context.request.references
      }
    )

    expectable_result_hook( result )

    return if result.adds_errors_to?( context.response.errors )

    array =
    [
      { 'listA'   => result                  },
      { 'listB'   => result                  },
      { 'listC'   => result                  },
      { 'options' => result.response_options }
    ]

    context.response.set_resources( array, ( result.dataset_size || 0 ) + 2 )
    context.response.set_estimated_resources( array, ( result.estimated_dataset_size || 0 ) + 2 )
  end

  def show( context )

    # (Exercise 'uri_path_components' array vs 'ident' in passing).

    repeat = context.request.ident == 'ensure_repeated_use_works' ? 10 : 1

    1.upto( repeat ) do

      resource = if ( context.request.uri_path_components[ 0 ] == 'generate_404' )
        context.resource( :NotFound, 42 )
      else
        context.resource( :TestEcho, 2 )
      end

      if ( context.request.ident == 'set_bad_inter_resource_identity' )
        resource.assume_identity_of = {
          MMRS_VALID_ASSUMED_IDENTITY_HASH.keys.first => Hoodoo::UUID.generate
        }
      elsif ( context.request.ident == 'set_good_inter_resource_identity' )
        resource.assume_identity_of = MMRS_VALID_ASSUMED_IDENTITY_HASH
      end

      result = resource.show(
        context.request.uri_path_components.join( ',' ),
        {
          '_embed'     => context.request.embeds,
          '_reference' => context.request.references
        }
      )

      expectable_result_hook( result )

      context.response.add_errors( result.platform_errors )
      context.response.body = { 'show' => result, 'options' => result.response_options }

    end
  end

  def create( context )
    endpoint = context.resource( :TestEcho, 2, dated_from: context.request.dated_from )

    if context.request.body[ 'foo' ] == 'specify_uuid'

      # If given the magic string "specify_uuid" in the mandatory resource
      # text field "foo", then specifically make an inter-resource call with
      # a resource UUID specified for the inner resource. This checks the
      # permissions handling on "internal" inter-resource calls.
      #
      # This is for *inter-resource* calls *from* this resource to the target
      # resource and has nothing to do with anything the top-level API caller
      # specified.
      #
      endpoint.resource_uuid = Hoodoo::UUID.generate()

    elsif context.request.body.has_key?( 'deja_vu_in_other_resource' )

      # This tests an inter-resource call specifying deja-vu and dealing with
      # responses.
      #
      endpoint.deja_vu = true

    end

    result = endpoint.create(
      context.request.body,
      {
        '_embed'     => context.request.embeds,
        '_reference' => context.request.references
      }
    )

    expectable_result_hook( result )

    context.response.add_errors( result.platform_errors )
    context.response.body = { 'create' => result, 'options' => result.response_options }
  end

  def update( context )
    resource = context.resource( :TestEcho, 2 )
    result   = resource.update(
      context.request.uri_path_components.join( ',' ),
      context.request.body,
      {
        '_embed'     => context.request.embeds,
        '_reference' => context.request.references
      }
    )

    expectable_result_hook( result )

    context.response.add_errors( result.platform_errors )
    context.response.body = { 'update' => result, 'options' => result.response_options }
  end

  def delete( context )
    resource = context.resource( :TestEcho, 2 )
    result   = resource.delete(
      context.request.uri_path_components.join( ',' ),
      {
        '_embed'     => context.request.embeds,
        '_reference' => context.request.references
      }
    )

    expectable_result_hook( result )

    context.response.add_errors( result.platform_errors )
    context.response.body = { 'delete' => result, 'options' => result.response_options }
  end

  # ...So we can expect any instance of this class to receive this message
  # and check on the data it was given.
  #
  def expectable_result_hook( result )
  end
end

class TestCallInterface < Hoodoo::Services::Interface
  interface :TestCall do
    endpoint :test_call, TestCallImplementation
  end
end

class TestCallService < Hoodoo::Services::Service
  comprised_of TestCallInterface
end

# A helper method for a set of common expectations.

def expect_response_headers_on( response, should_not_have_called_service = false )
  expect( response[ 'X-Interaction-ID' ] ).to_not be_nil
  expect( Hoodoo::UUID.valid?( response[ 'X-Interaction-ID' ] ) ).to eq( true )

  if should_not_have_called_service
    expect( response[ 'X-Service-Response-Time' ] ).to     be_nil
  else
    expect( response[ 'X-Service-Response-Time' ] ).to_not be_nil
  end
end

# And Finally - the tests.

describe 'DRb start timeout' do
  context 'for test coverage purposes' do
    it 'checks for timeouts' do
      expect( DRbObject ).to receive( :new_with_uri ).once.and_raise( DRb::DRbConnError )
      expect( DRbObject ).to receive( :new_with_uri ).at_least( :once ).and_raise( Timeout::Error )

      spec_helper_http(
        port: spec_helper_start_svc_app_in_thread_for( TestEchoService ),
        path: '/v2/test_some_echoes' # Test 'old' route
      )
    end
  end
end

describe Hoodoo::Services::Middleware do

  before :each do
    @old_test_session = Hoodoo::Services::Middleware.test_session()

    @test_session = @old_test_session.dup
    @test_session.caller_fingerprint = @caller_fingerprint = Hoodoo::UUID.generate()

    permissions = Hoodoo::Services::Permissions.new # (this is "default-else-deny")
    permissions.set_default_fallback( Hoodoo::Services::Permissions::ALLOW )
    @test_session.permissions = permissions

    @test_session.scoping = @test_session.scoping.dup
    @test_session.scoping.authorised_http_headers = [] # (no secured headers allowed to start with)

    Hoodoo::Services::Middleware.set_test_session( @test_session )
  end

  after :each do
    Hoodoo::Services::Middleware.set_test_session( @old_test_session )
  end

  before :all do
    @port = spec_helper_start_svc_app_in_thread_for( TestEchoService )
  end

  # Although tests can run in random order so we can't force this set to come
  # first, at least having this set present validates all of the HTTP behaviour
  # we expect to work in the echo service. If these tests fail, all bets are
  # off for anything else tested here.
  #
  context 'with in-thread HTTP service' do

    before :example, :check_callbacks => true do
      expect_any_instance_of( TestEchoImplementation ).to receive( :before ).once
      expect_any_instance_of( TestEchoImplementation ).to receive( :after ).once
    end

    before :example, :check_quiet_callbacks => true do
      expect_any_instance_of( TestEchoQuietImplementation ).to receive( :before ).once
      expect_any_instance_of( TestEchoQuietImplementation ).to receive( :after ).once
    end

    def list_things( locale: nil, dated_at: nil, deja_vu: nil )
      headers = {}
      headers[ 'Accept-Language' ] = locale unless locale.nil?
      headers[ 'X-Dated-At'      ] = Hoodoo::Utilities.nanosecond_iso8601( dated_at ) unless dated_at.nil?
      headers[ 'X-Deja-Vu'       ] = 'yes' if deja_vu == true

      response = spec_helper_http(
        port:    @port,
        path:    '/2/TestEcho.tar.gz?limit=25&offset=75&_reference=embed_one,embed_two',
        headers: headers
      )

      expect( response.code ).to eq( '200' )
      expect_response_headers_on( response )

      parsed = JSON.parse( response.body )

      expect( parsed[ '_data' ]).to_not be_nil
      expect( parsed[ '_data' ][ 0 ]).to_not be_nil
      expect( parsed[ '_data' ][ 0 ][ 'list0' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'dated_from'          => '',
          'deja_vu'             => deja_vu.to_s,
          'resource_uuid'       => '',
          'body'                => nil,
          'uri_path_components' => [],
          'uri_path_extension'  => 'tar.gz',
          'list_offset'         => 75,
          'list_limit'          => 25,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [ 'embed_one', 'embed_two' ],
          'session_hash'        => @test_session.to_h
        }
      )
      expect( parsed[ '_dataset_size' ] ).to eq( 49 )
      expect( parsed[ '_estimated_dataset_size' ] ).to eq( 50 )
    end

    it 'lists things with callbacks', :check_callbacks => true do
      list_things()
    end

    it 'list things without callbacks' do
      list_things()
    end

    it 'lists things with a custom locale and dated-at time' do
      list_things( locale: 'foo', dated_at: DateTime.now )
    end

    it 'should be able to list quiet things too, reporting HTTP headers', :check_quiet_callbacks => true do

      # Did this test give you a 500? Chances are it's the "raise" below,
      # but checking 'test.log' or adding "puts response.body.inspect" a
      # bit further down will let you know for sure.

      expect_any_instance_of( TestEchoQuietImplementation ).to receive( :expectable_hook ) { | ignored, context |
        raise 'Test failed as context.request.headers not frozen' unless context.request.headers.frozen?
      }

      response = spec_helper_http(
        port: @port,
        path: '/1/TestEchoQuiet'
      )

      expect( response.code ).to eq( '200' )
      expect_response_headers_on( response )

      parsed = JSON.parse( response.body )

      expect( parsed[ '_data' ] ).to eq( [ {
        'CONTENT_TYPE'    => 'application/json; charset=utf-8',
        'HTTP_CONNECTION' => 'close',
        'HTTP_HOST'       => "127.0.0.1:#{ @port }"
      } ] )
    end

    # Code coverage: At present the middleware always calls its "remove
    # expected errors" method if deja-vu is on and there are errors in the
    # response. This method then filters based on action, with an early
    # exit for non-create, non-delete cases. We're testing that here.
    #
    it 'lists things without worrying about deja-vu' do
      expect_any_instance_of( TestEchoImplementation ).to receive( :list ).once do | ignored_rspec_mock_instance, context |
        context.response.not_found( 'some_error' )
      end

      expect_any_instance_of( Hoodoo::Services::Middleware ).to receive( :remove_expected_errors_when_experiencing_deja_vu ).once.and_call_original

      response = spec_helper_http(
        port:    @port,
        path:    '/v2/test_some_echoes', # Test 'old' route
        headers: { 'X-Deja-Vu' => 'yes' }
      )

      expect( response.code ).to eq( '404' )
      expect_response_headers_on( response )
    end

    def show_things( locale: nil, dated_at: nil )
      headers = {}
      headers[ 'Accept-Language' ] = locale unless locale.nil?
      headers[ 'X-Dated-At'      ] = Hoodoo::Utilities.nanosecond_iso8601( dated_at ) unless dated_at.nil?

      response = spec_helper_http(
        port:    @port,
        path:    '/2/TestEcho/one/two.tar.gz?_reference=embed_one,embed_two', # Test 'new' route
        headers: headers
      )

      expect( response.code ).to eq( '200' )
      expect_response_headers_on( response )

      parsed = JSON.parse( response.body )

      expect( parsed[ 'show' ] ).to_not be_nil
      expect( parsed[ 'show' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'dated_from'          => '',
          'deja_vu'             => '',
          'resource_uuid'       => '',
          'body'                => nil,
          'uri_path_components' => [ 'one', 'two' ],
          'uri_path_extension'  => 'tar.gz',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [ 'embed_one', 'embed_two' ],
          'session_hash'        => @test_session.to_h
        }
      )
    end

    it 'shows_things_with_callbacks', :check_callbacks => true do
      show_things( locale: 'fr' )
    end

    it 'shows_things_without_callbacks' do
      show_things()
    end

    it 'shows things with a custom locale and dated-at time' do
      show_things( locale: 'bar', dated_at: DateTime.now )
    end

    it 'should be able to show quiet things too', :check_quiet_callbacks => true do

      response = spec_helper_http(
        port: @port,
        path: '/1/TestEchoQuiet/some_uuid'
      )

      expect( response.code ).to eq( '200' )
      expect_response_headers_on( response )

      parsed = JSON.parse( response.body )

      expect( parsed[ 'show' ] ).to_not be_nil
      expect( parsed[ 'show' ] ).to eq(
        {
          'locale'              => 'en-nz',
          'dated_at'            => '',
          'dated_from'          => '',
          'deja_vu'             => '',
          'resource_uuid'       => '',
          'body'                => nil,
          'uri_path_components' => [ 'some_uuid' ],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [],
          'session_hash'        => @test_session.to_h
        }
      )
    end

    def create_things( locale: nil, dated_from: nil, deja_vu: nil, resource_uuid: nil )
      headers = {}
      headers[ 'Accept-Language' ] = locale unless locale.nil?
      headers[ 'X-Resource-UUID' ] = resource_uuid unless resource_uuid.nil?
      headers[ 'X-Dated-From'    ] = Hoodoo::Utilities.nanosecond_iso8601( dated_from ) unless dated_from.nil?
      headers[ 'X-Deja-Vu'       ] = 'yes' if deja_vu == true

      response = spec_helper_http(
        klass:   Net::HTTP::Post,
        port:    @port,
        path:    '/2/TestEcho.json?_embed=embed_one,embed_two',
        body:    { 'foo' => 'bar', 'baz' => 'boo' }.to_json,
        headers: headers
      )

      if deja_vu
        expect( response.code ).to eq( '204' )
        expect( response.body ).to be_nil
        expect_response_headers_on( response )

      else
        expect( response.code ).to eq( '200' )
        expect_response_headers_on( response )

        parsed = JSON.parse( response.body )

        expected_body = { 'foo' => 'bar', 'baz' => 'boo' }
        expected_body[ 'id' ] = resource_uuid unless resource_uuid.nil?

        expect( parsed[ 'create' ] ).to_not be_nil
        expect( parsed[ 'create' ] ).to eq(
          {
            'locale'              => locale.nil? ? 'en-nz' : locale,
            'dated_at'            => '',
            'dated_from'          => dated_from.to_s,
            'deja_vu'             => deja_vu.to_s,
            'resource_uuid'       => resource_uuid.to_s,
            'body'                => expected_body,
            'uri_path_components' => [],
            'uri_path_extension'  => 'json',
            'list_offset'         => 0,
            'list_limit'          => 50,
            'list_sort_data'      => { 'created_at' => 'desc' },
            'list_search_data'    => {},
            'list_filter_data'    => {},
            'embeds'              => [ 'embed_one', 'embed_two' ],
            'references'          => [],
            'session_hash'        => @test_session.to_h
          }
        )

      end
    end

    it 'creates things with callbacks', :check_callbacks => true do
      create_things()
    end

    it 'creates things without callbacks' do
      create_things()
    end

    it 'creates things with a custom locale, dated_from and deja_vu' do
      create_things( locale: 'baz', dated_from: DateTime.now, deja_vu: true )
    end

    # Extra test coverage for this is present in middleware_create_update_spec.rb.
    #
    it 'creates things with a custom UUID given permission' do
      @test_session.scoping.authorised_http_headers = [ 'HTTP_X_RESOURCE_UUID' ]
      create_things(resource_uuid: Hoodoo::UUID.generate())
    end

    # Extra test coverage for this is present in middleware_create_update_spec.rb.
    #
    it 'fails to create things with a custom UUID if not given permission' do
      response = spec_helper_http(
        klass:   Net::HTTP::Post,
        port:    @port,
        path:    '/2/TestEcho.json',
        body:    { 'foo' => 'bar', 'baz' => 'boo' }.to_json,
        headers: { 'X-Resource-UUID' => Hoodoo::UUID.generate() }
      )

      expect( response.code ).to eq( '403' )
      expect_response_headers_on( response, true ) # true => shouldn't have called service

      parsed = JSON.parse( response.body )

      expect( parsed[ 'errors' ].size ).to eq( 1 )
      expect( parsed[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
      expect( parsed[ 'errors' ][ 0 ][ 'reference' ] ).to be_nil # Ensure no information disclosure vulnerability
    end

    it 'gets a 204 with deja-vu and duplication' do
      response = spec_helper_http(
        klass:   Net::HTTP::Post,
        port:    @port,
        path:    '/2/TestEcho',
        body:    { 'foo' => 'bar' }.to_json,
        headers: { 'X-Deja-Vu' => 'yes' }
      )

      expect( response.code ).to eq( '204' )
      expect( response.body ).to be_nil

      expect_response_headers_on( response )
      expect( response[ 'X-Deja-Vu' ] ).to eq( 'confirmed' )
    end

    it 'gets non-204 with deja-vu and duplication plus other errors' do
      response = spec_helper_http(
        klass:   Net::HTTP::Post,
        port:    @port,
        path:    '/2/TestEcho',
        body:    { 'foo' => 'bar', 'additional_error' => 'generic.invalid_decimal' }.to_json,
        headers: { 'X-Deja-Vu' => 'yes' }
      )

      expect( response.code ).to eq( '422' )
      expect_response_headers_on( response )

      parsed = JSON.parse( response.body )

      expect( parsed[ 'errors' ].size ).to eq( 2 )
      expect( parsed[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'generic.invalid_duplication' )
      expect( parsed[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'deja_vu' )
      expect( parsed[ 'errors' ][ 1 ][ 'code'      ] ).to eq( 'generic.invalid_decimal' )
      expect( parsed[ 'errors' ][ 1 ][ 'reference' ] ).to eq( 'deja_vu' )
    end

    def update_things( locale: nil )
      headers = {}
      headers[ 'Accept-Language' ] = locale unless locale.nil?

      response = spec_helper_http(
        klass:   Net::HTTP::Patch,
        port:    @port,
        path:    '/2/TestEcho/a/b.json?_embed=embed_one',
        body:    { 'foo' => 'boo', 'baz' => 'bar' }.to_json,
        headers: headers
      )

      expect( response.code ).to eq( '200' )
      expect_response_headers_on( response )

      parsed = JSON.parse( response.body )

      expect( parsed[ 'update' ] ).to_not be_nil
      expect( parsed[ 'update' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => '',
          'dated_from'          => '',
          'deja_vu'             => '',
          'resource_uuid'       => '',
          'body'                => { 'foo' => 'boo', 'baz' => 'bar' },
          'uri_path_components' => [ 'a', 'b' ],
          'uri_path_extension'  => 'json',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [ 'embed_one' ],
          'references'          => [],
          'session_hash'        => @test_session.to_h
        }
      )
    end

    it 'updates things with callbacks', :check_callbacks => true do
      update_things()
    end

    it 'updates things without callbacks' do
      update_things()
    end

    it 'updates things with a custom locale' do
      update_things( locale: 'boo' )
    end

    def delete_things( locale: nil, deja_vu: nil )
      headers = {}
      headers[ 'Accept-Language' ] = locale unless locale.nil?
      headers[ 'X-Deja-Vu'       ] = 'yes' if  deja_vu == true

      response = spec_helper_http(
        klass:   Net::HTTP::Delete,
        port:    @port,
        path:    '/2/TestEcho/aa/bb.xml.gz?_embed=embed_two',
        headers: headers
      )

      expect( response.code ).to eq( '200' )
      expect_response_headers_on( response )

      parsed = JSON.parse( response.body )

      expect( parsed[ 'delete' ] ).to_not be_nil
      expect( parsed[ 'delete' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => '',
          'dated_from'          => '',
          'deja_vu'             => deja_vu.to_s,
          'resource_uuid'       => '',
          'body'                => nil,
          'uri_path_components' => [ 'aa', 'bb' ],
          'uri_path_extension'  => 'xml.gz',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [ 'embed_two' ],
          'references'          => [],
          'session_hash'        => @test_session.to_h
        }
      )
    end

    it 'deletes things with callbacks', :check_callbacks => true do
      delete_things()
    end

    it 'deletes things without callbacks' do
      delete_things()
    end

    it 'deletes things, passing through custom locale and deja_vu' do
      delete_things( locale: 'bye', deja_vu: true )
    end

    it 'deletes things with a simulated 404' do
      response = spec_helper_http(
        klass:   Net::HTTP::Delete,
        port:    @port,
        path:    '/2/TestEcho/simulate_404' )

      expect( response.code ).to eq( '404' )
      expect_response_headers_on( response )

      parsed = JSON.parse( response.body )

      expect( parsed[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'generic.not_found' )
    end

    it 'deletes things with a 204 with deja vu' do
      response = spec_helper_http(
        klass:   Net::HTTP::Delete,
        port:    @port,
        path:    '/2/TestEcho/simulate_404',
        headers: { 'X-Deja-Vu' => 'yes' }
      )

      expect( response.code ).to eq( '204' )
      expect( response.body ).to be_nil
      expect( response[ 'X-Deja-Vu' ] ).to eq( 'confirmed' )
      expect_response_headers_on( response )
    end

    it 'should get 405 for bad requests' do

      # Attempt a #create (POST with body data) - service only does "show"
      # and "list".

      response = spec_helper_http(
        klass: Net::HTTP::Post,
        port:  @port,
        path:  '/1/TestEchoQuiet',
        body:  { 'foo' => 'bar', 'baz' => 'boo' }.to_json
      )

      expect( response.code ).to eq( '405' )
      expect_response_headers_on( response, true ) # true => shouldn't have called service
    end

    it 'should be detect 404 OK' do
      response = spec_helper_http(
        port: @port,
        path: '/1/NotPresent'
      )

      expect( response.code ).to eq( '404' )
      expect_response_headers_on( response, true ) # true => shouldn't have called service
    end
  end

  #############################################################################

  context 'remote inter-resource calls' do
    def app
      Rack::Builder.new do
        use Hoodoo::Services::Middleware
        run TestCallService.new
      end
    end

    before :example, :check_callbacks => true do
      expect_any_instance_of( TestCallImplementation ).to receive( :before ).once
        expect_any_instance_of( TestEchoImplementation ).to receive( :before ).once
        expect_any_instance_of( TestEchoImplementation ).to receive( :after ).once
      expect_any_instance_of( TestCallImplementation ).to receive( :after ).once
    end

    def headers_for( locale:        nil,
                     dated_at:      nil,
                     dated_from:    nil,
                     deja_vu:       nil,
                     resource_uuid: nil )

      headers = {
        'HTTP_X_INTERACTION_ID' => @interaction_id,
        'CONTENT_TYPE'          => 'application/json; charset=utf-8'
      }

      headers[ 'HTTP_CONTENT_LANGUAGE' ] = locale unless locale.nil?
      headers[ 'HTTP_ACCEPT_LANGUAGE'  ] = locale unless locale.nil?
      headers[ 'HTTP_X_RESOURCE_UUID'  ] = resource_uuid unless resource_uuid.nil?
      headers[ 'HTTP_X_DATED_AT'       ] = Hoodoo::Utilities.nanosecond_iso8601( dated_at ) unless dated_at.nil?
      headers[ 'HTTP_X_DATED_FROM'     ] = Hoodoo::Utilities.nanosecond_iso8601( dated_from ) unless dated_from.nil?
      headers[ 'HTTP_X_DEJA_VU'        ] = 'yes' if deja_vu == true

      return headers
    end

    # A helper method for a set of common expectations.

    def expect_response_options_for( options )
      expect( options ).to_not be_nil
      expect( options[ 'service_response_time' ] ).to_not be_nil
      expect( options[ 'interaction_id'        ] ).to_not be_nil
      expect( Hoodoo::UUID.valid?( options[ 'interaction_id' ] ) ).to eq( true )
    end

    def list_things( locale: nil, dated_at: nil )
      get(
        '/1/TestCall.tar.gz?limit=25&offset=75',
        nil,
        headers_for( locale: locale, dated_at: dated_at )
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      # Outer calls wrap arrays in object with "_data" key for JSON (since we
      # don't do JSON5 and only JSON5 allows outermost / top-level arrays), but
      # the inter-resource calls unpack that for us, so we should see the outer
      # service's "_data" array nesting directly the inner service's array if
      # the middleware dereferenced it correctly for us.

      expect( parsed[ '_data' ]).to_not be_nil
      expect( parsed[ '_data' ][ 0 ]).to_not be_nil
      expect( parsed[ '_data' ][ 0 ][ 'listA' ] ).to_not be_nil
      expect( parsed[ '_data' ][ 0 ][ 'listA' ][ 0 ] ).to_not be_nil
      expect( parsed[ '_data' ][ 0 ][ 'listA' ][ 0 ][ 'list0'] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'dated_from'          => '',
          'deja_vu'             => '',
          'resource_uuid'       => '',
          'body'                => nil,
          'uri_path_components' => [],
          'uri_path_extension'  => '',
          'list_offset'         => 75,
          'list_limit'          => 25,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [],
          'session_hash'        => @test_session.to_h
        }
      )

      expect( parsed[ '_dataset_size' ]).to eq( 51 )
      expect( parsed[ '_estimated_dataset_size' ] ).to eq( 52 )

      expect( parsed[ '_data' ][ 3 ] ).to_not be_nil
      expect_response_options_for( parsed[ '_data' ][ 3 ][ 'options' ] )
    end

    it 'list things in the remote service with callbacks', :check_callbacks => true do
      list_things()
    end

    it 'list things in the remote service without callbacks' do
      list_things()
    end

    it 'lists things with a custom locale and dated-at time' do
      list_things( locale: 'foo', dated_at: DateTime.now )
    end

    it 'complains if the JSON implementation is not up to scratch' do
      module JSON
        class << self
          def dumb_parse( data, ignored )
            JSON.original_parse( data )
          end

          alias original_parse parse
          alias parse dumb_parse
        end
      end

      get(
        '/1/TestCall.tar.gz?limit=25&offset=75',
        nil,
        headers_for( locale: 'de' )
      )

      module JSON
        class << self
          alias parse original_parse
        end
      end

      expect( last_response.status ).to eq( 500 )
      expect_response_headers_on( last_response, true ) # true => shouldn't have called service

      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'errors' ][ 0 ][ 'message' ] ).to eq( "Hoodoo::Services::Middleware: Incompatible JSON implementation in use which doesn't understand 'object_class' or 'array_class' options" )
    end

    it 'gets the correct type back when an inter-resource remote call generates an error' do
      expect_any_instance_of( TestCallImplementation ).to receive( :expectable_result_hook ) do | instance, result |
        expect( result ).to be_a( Hoodoo::Client::AugmentedArray )
        expect( result.platform_errors.has_errors? ).to eq( true )
      end

      get(
        '/1/TestCall.tar.gz?offset=42', # 42 -> magic -> inner service adds error
        nil,
        headers_for( locale: 'de' )
      )

      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.malformed')
    end

    def show_things( locale: nil, dated_at: nil )
      get(
        '/1/TestCall/one/two.tar.gz',
        nil,
        headers_for( locale: locale, dated_at: dated_at )
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'show' ]).to_not be_nil
      expect( parsed[ 'show' ][ 'show' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'dated_from'          => '',
          'deja_vu'             => '',
          'resource_uuid'       => '',
          'body'                => nil,
          'uri_path_components' => [ 'one,two' ],
          'uri_path_extension'  => '', # This is the *inner* inter-resource call's state and no filename extensions are used internally
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [],
          'session_hash'        => @test_session.to_h
        }
      )

      expect( parsed[ 'options' ] ).to_not be_nil
      expect_response_options_for( parsed[ 'options' ] )
    end

    it 'shows things in the remote service with callbacks', :check_callbacks => true do
      show_things()
    end

    it 'shows things in the remote service without callbacks' do
      show_things()
    end

    it 'shows things with a custom locale and dated-at time' do
      show_things( locale: 'bar', dated_at: DateTime.now )
    end

    it 'gets the correct type back when an inter-resource remote call generates an error' do
      expect_any_instance_of( TestCallImplementation ).to receive( :expectable_result_hook ) do | instance, result |
        expect( result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( result.platform_errors.has_errors? ).to eq( true )
      end

      get( '/1/TestCall/return_error', nil, headers_for() )

      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('generic.invalid_string')
    end

    it 'gets the correct type back when an inter-resource remote call returns invalid data' do
      expect_any_instance_of( TestCallImplementation ).to receive( :expectable_result_hook ) do | instance, result |
        expect( result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( result.platform_errors.has_errors? ).to eq( true )
      end

      get( '/1/TestCall/return_invalid_data', nil, headers_for() )

      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.fault')
      expect(result['errors'][0]['message']).to eq('Could not parse retrieved body data despite receiving HTTP status code 200')
    end

    context 'X-Assume-Identity-Of' do
      context 'top-level use permitted' do
        before :each do
          @old_test_session = Hoodoo::Services::Middleware.test_session()

          test_session          = @old_test_session.dup
          test_session.identity = test_session.identity.dup
          test_session.scoping  = test_session.scoping.dup

          test_session.scoping.authorised_http_headers = [ 'X-Assume-Identity-Of' ]
          test_session.scoping.authorised_identities   = {
            MMRS_VALID_ASSUMED_IDENTITY_HASH.keys.first =>
            [ MMRS_VALID_ASSUMED_IDENTITY_HASH.values.first ]
          }

          Hoodoo::Services::Middleware.set_test_session( test_session )
        end

        after :each do
          Hoodoo::Services::Middleware.set_test_session( @old_test_session )
        end

        context 'when in use at top level' do
          it 'sees correct identity in the downstream resource' do
            get(
              '/1/TestCall/return_identity',
              nil,
              {
                'CONTENT_TYPE' => 'application/json; charset=utf-8',
                'HTTP_X_ASSUME_IDENTITY_OF' => URI.encode_www_form( MMRS_VALID_ASSUMED_IDENTITY_HASH )
              }
            )

            result = JSON.parse( last_response.body )

            expect( result[ 'show' ] ).to eq( {
              'identity'    => MMRS_VALID_ASSUMED_IDENTITY_HASH,
              'fingerprint' => @caller_fingerprint
            } )
          end

          it 'cannot set an illegal identity in the inter-resource call' do
            get(
              '/1/TestCall/set_bad_inter_resource_identity',
              nil,
              {
                'CONTENT_TYPE' => 'application/json; charset=utf-8',
                'HTTP_X_ASSUME_IDENTITY_OF' => URI.encode_www_form( MMRS_VALID_ASSUMED_IDENTITY_HASH )
              }
            )

            expect( last_response.status ).to eq( 403 )
            result = JSON.parse( last_response.body )
            expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          end
        end

        context 'in inter-resource call only' do
          it 'can still set identity for the downstream resource' do
            get(
              '/1/TestCall/set_good_inter_resource_identity',
              nil,
              { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
            )

            result = JSON.parse( last_response.body )

            expect( result[ 'show' ] ).to eq( {
              'identity'    => MMRS_VALID_ASSUMED_IDENTITY_HASH,
              'fingerprint' => @caller_fingerprint
            } )
          end

          it 'cannot set an illegal identity for the downstream resource' do
            get(
              '/1/TestCall/set_bad_inter_resource_identity',
              nil,
              { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
            )

            expect( last_response.status ).to eq( 403 )
            result = JSON.parse( last_response.body )
            expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'X-Assume-Identity-Of header value requests a prohibited identity quantity' )
          end
        end
      end

      context 'top-level use prohibited' do
        before :each do
          @old_test_session = Hoodoo::Services::Middleware.test_session()

          test_session          = @old_test_session.dup
          test_session.identity = test_session.identity.dup
          test_session.scoping  = test_session.scoping.dup

          test_session.scoping.authorised_http_headers = [] # NO ALLOWED HEADERS
          test_session.scoping.authorised_identities   = { 'caller_id' => [ MMRS_CUSTOM_CALLER_ID ] }

          Hoodoo::Services::Middleware.set_test_session( test_session )
        end

        after :each do
          Hoodoo::Services::Middleware.set_test_session( @old_test_session )
        end

        # middleware_assumed_identity_spec.rb already comprehensively tests
        # top-level calls, so just do the inter-resource check here.
        #
        it 'cannot override a valid identity in inter-resource calls' do
          get(
            '/1/TestCall/set_good_inter_resource_identity',
            nil,
            { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
          )

          expect( last_response.status ).to eq( 403 )
          result = JSON.parse( last_response.body )
          expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
        end
      end
    end

    def create_things( locale: nil, dated_from: nil, deja_vu: nil, resource_uuid: nil )
      post(
        '/1/TestCall.tar.gz',
        { 'foo' => 'bar', 'baz' => 'boo' }.to_json,
        headers_for( locale: locale, dated_from: dated_from, deja_vu: deja_vu, resource_uuid: resource_uuid )
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'create' ]).to_not be_nil
      expect( parsed[ 'create' ][ 'create' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => '',
          'dated_from'          => dated_from.to_s,
          'deja_vu'             => '', # Not passed through
          'resource_uuid'       => '', # Not passed through
          'body'                => { 'foo' => 'bar', 'baz' => 'boo' },
          'uri_path_components' => [],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [],
          'session_hash'        => @test_session.to_h
        }
      )

      expect( parsed[ 'options' ] ).to_not be_nil
      expect_response_options_for( parsed[ 'options' ] )
    end

    it 'creates things in the remote service with callbacks', :check_callbacks => true do
      create_things()
    end

    it 'creates things in the remote service without callbacks' do
      create_things()
    end

    it 'creates things with a custom locale, passes through dated_from but not deja_vu' do
      create_things( locale: 'baz', dated_from: DateTime.now, deja_vu: true )
    end

    it 'can specify a UUID via an inter-resource call if it has top-level permission' do
      @test_session.scoping.authorised_http_headers = [ 'HTTP_X_RESOURCE_UUID' ]

      post(
        '/1/TestCall.tar.gz',
         { :foo => 'specify_uuid' }.to_json,
         headers_for()
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'create' ]).to_not be_nil
      resource_uuid = parsed[ 'create' ][ 'create' ][ 'resource_uuid' ]
      expect( Hoodoo::UUID.valid?( resource_uuid ) ).to eq( true )
    end

    it 'cannot specify a UUID via an inter-resource call if it does not have top-level permission' do
      post(
        '/1/TestCall.tar.gz',
         { :foo => 'specify_uuid' }.to_json,
         headers_for()
      )

      expect( last_response.status ).to eq( 403 )
      expect_response_headers_on( last_response ) # should call target service, but fails on inter-resource call

      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'errors' ].size ).to eq( 1 )
      expect( parsed[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.forbidden' )
      expect( parsed[ 'errors' ][ 0 ][ 'reference' ] ).to be_nil # Ensure no information disclosure vulnerability
    end

    # Remember this time the deja-vu stuff is happening one level down,
    # as an inter-resource call, not at the top level per the similar
    # tests that use spec_helper_http in the previous major "section"
    # of this file.
    #
    it 'gets a 204 with deja-vu and duplication' do
      post(
        '/1/TestCall.tar.gz',
         { 'foo' => 'bar', 'deja_vu_in_other_resource' => 'yes' }.to_json,
         headers_for() # *not* requesting Deja-Vu at the top level
      )

      # If the test passes, the inter-resource call returned the equivlant
      # of a 204, so the parsed payload giving us the result of that call
      # will show an empty Hash and a 'confirmed' option from the endpoint.

      expect( last_response.status ).to eq( 200 )
      expect_response_headers_on( last_response )

      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'create' ] ).to eq( {} )
      expect( parsed[ 'options' ][ 'deja_vu' ] ).to eq( 'confirmed' )
    end

    it 'gets non-204 with deja-vu and duplication plus other errors' do
      post(
        '/1/TestCall.tar.gz',
         {
           'foo'                       => 'bar',
           'deja_vu_in_other_resource' => 'yes',
           'additional_error'          => 'generic.invalid_decimal'
         }.to_json,
         headers_for() # *not* requesting Deja-Vu at the top level
      )

      # If the test passes, the inter-resource call will add other errors
      # that aren't just duplication, so the call returns the full error
      # set normally rather than via a 204 response equivalent. Normal
      # error handling in the calling resource therefore takes place.

      expect( last_response.status ).to eq( 422 )
      expect_response_headers_on( last_response )

      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'errors' ].size ).to eq( 2 )
      expect( parsed[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'generic.invalid_duplication' )
      expect( parsed[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'deja_vu' )
      expect( parsed[ 'errors' ][ 1 ][ 'code'      ] ).to eq( 'generic.invalid_decimal' )
      expect( parsed[ 'errors' ][ 1 ][ 'reference' ] ).to eq( 'deja_vu' )
    end

    it 'rejects non-deja-vu 204 responses' do
      expect_any_instance_of( Hoodoo::Client::Endpoint::HTTPBased::DescriptionOfResponse ).to receive( :http_status_code ).and_return( 204        )
      expect_any_instance_of( Hoodoo::Client::Endpoint::HTTPBased::DescriptionOfResponse ).to receive( :raw_body_data    ).and_return( 'not JSON' )

      post(
        '/1/TestCall.tar.gz',
         { 'foo' => 'bar' }.to_json,
         headers_for()
      )

      expect( last_response.status ).to eq( 500 )
      expect_response_headers_on( last_response )

      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'errors' ].size ).to eq( 1 )
      expect( parsed[ 'errors' ][ 0 ][ 'code'      ] ).to eq( 'platform.fault' )
      expect( parsed[ 'errors' ][ 0 ][ 'message'   ] ).to eq( "Unexpected raw HTTP status code 204 with 'X-Deja-Vu: confirmed' not present" )
      expect( parsed[ 'errors' ][ 0 ][ 'reference' ] ).to eq( '204' )
    end

    it 'gets the correct type back when an inter-resource remote call generates an error' do
      expect_any_instance_of( TestCallImplementation ).to receive( :expectable_result_hook ) do | instance, result |
        expect( result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( result.platform_errors.has_errors? ).to eq( true )
      end

      post(
        '/1/TestCall.tar.gz',
         { :foo => 'bar', :return_error => 'yes' }.to_json,
         headers_for()
      )

      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.malformed')
    end

    def update_things( locale: nil )
      patch(
        '/1/TestCall/aa/bb.tar.gz',
        { 'foo' => 'boo', 'baz' => 'bar' }.to_json,
        headers_for( locale: locale )
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'update' ]).to_not be_nil
      expect( parsed[ 'update' ][ 'update' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => '',
          'dated_from'          => '',
          'deja_vu'             => '',
          'resource_uuid'       => '',
          'body'                => { 'foo' => 'boo', 'baz' => 'bar' },
          'uri_path_components' => [ 'aa,bb' ],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [],
          'session_hash'        => @test_session.to_h
        }
      )

      expect( parsed[ 'options' ] ).to_not be_nil
      expect_response_options_for( parsed[ 'options' ] )
      expect( parsed[ 'options' ][ 'example_header' ] ).to eq( 'example' )
    end

    it 'updates things in the remote service with callbacks', :check_callbacks => true do
      update_things()
    end

    it 'updates things in the remote service without callbacks' do
      update_things()
    end

    it 'updates things with a custom locale' do
      update_things( locale: 'boo' )
    end

    it 'gets the correct type back when an inter-resource remote call generates an error' do
      expect_any_instance_of( TestCallImplementation ).to receive( :expectable_result_hook ) do | instance, result |
        expect( result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( result.platform_errors.has_errors? ).to eq( true )
      end

      patch( '/1/TestCall/return_error', '{}', headers_for() )

      result = JSON.parse(last_response.body)
      expect(result['errors'][0]['code']).to eq('platform.malformed')
    end

    def delete_things( locale: nil, deja_vu: nil )
      delete(
        '/1/TestCall/aone/btwo.tar.gz',
        nil,
        headers_for( locale:locale, deja_vu: deja_vu )
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'delete' ]).to_not be_nil
      expect( parsed[ 'delete' ][ 'delete' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => '',
          'dated_from'          => '',
          'deja_vu'             => '', # Not passed through
          'resource_uuid'       => '', # Not passed through
          'body'                => nil,
          'uri_path_components' => [ 'aone,btwo' ],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [],
          'session_hash'        => @test_session.to_h
        }
      )

      expect( parsed[ 'options' ] ).to_not be_nil
      expect_response_options_for( parsed[ 'options' ] )
    end

    it 'deletes things in the remote service with callbacks', :check_callbacks => true do
      delete_things()
    end

    it 'deletes things in the remote service without callbacks' do
      delete_things()
    end

    it 'deletes things, passing through custom locale but not deja_v' do
      delete_things( locale: 'bye', deja_vu: true )
    end

    it 'should receive errors from remote service as if from the local call' do
      get(
        '/1/TestCall/return_error',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 422 )
      expect_response_headers_on( last_response )

      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'errors' ] ).to_not be_nil
      expect( parsed[ 'errors' ].count ).to eq(1)
      expect( parsed[ 'errors' ][ 0 ] ).to eq({
        'code'      => 'generic.invalid_string',
        'message'   => 'Returning error as requested',
        'reference' => 'no ident,no other ident'
      })
    end

    it 'gets a 404 for missing endpoints (and gets correct type back when inter-resource call generates an error)' do
      expect_any_instance_of( TestCallImplementation ).to receive( :expectable_result_hook ) do | instance, result |
        expect( result ).to be_a( Hoodoo::Client::AugmentedHash )
        expect( result.platform_errors.has_errors? ).to eq( true )
      end

      get(
        '/1/TestCall/generate_404',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 404 )
      expect_response_headers_on( last_response )
    end

    it 'can reuse an endpoint' do
      get(
        '/1/TestCall/ensure_repeated_use_works',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 200 )
      expect_response_headers_on( last_response )

      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'show' ]).to_not be_nil
      expect( parsed[ 'show' ][ 'show' ][ 'uri_path_components' ] ).to eq( [ 'ensure_repeated_use_works' ] )

      expect( parsed[ 'options' ] ).to_not be_nil
      expect_response_options_for( parsed[ 'options' ] )
    end

    # Ruby can't kill off an "unresponsive" thread - there seems to be no
    # equivalent of "kill -9" and the likes of "#exit!" are long gone - so
    # the WEBrick server thread, which never returns to the Ruby interpreter
    # after the Rackup::Server.start() call (or equivalent) can't die. Instead
    # we are forced to write a fragile test that simulates a connection
    # failure to the endpoint.
    #
    it 'should get a 404 for no-longer-running endpoints' do
      expect_any_instance_of( Net::HTTP ).to receive( :request ).once.and_raise( Errno::ECONNREFUSED )

      get(
        '/1/TestCall/show_something',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 404 )
      expect_response_headers_on( last_response ) # should call target service, but fails on inter-resource call
    end

    # Similarly shaky test for simulating arbitrary other failure kinds.
    #
    it 'should get a 500 for arbitrary failures' do
      expect_any_instance_of( Net::HTTP ).to receive( :request ).once.and_raise( 'some connection error' )

      get(
        '/1/TestCall/show_something',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 500 )
      expect( last_response.body ).to include( 'some connection error' )
      expect_response_headers_on( last_response )
    end
  end
end
