# service_middleware_spec.rb is too large and this set of tests is weird
# anyway - we want to test inter-resource remote calls, so we start multiple
# HTTP server instances in threads and have them talk to each other.

require 'spec_helper'
require 'json'

# First, a test service comprised of a couple of 'echo' variants which we use
# to make sure they're both correctly stored in the DRb registry.

class TestEchoImplementation < Hoodoo::Services::Implementation

  public

    def list( context )
      context.response.set_resources(
        [
          { 'list0' => to_h( context ) },
          { 'list1' => to_h( context ) },
          { 'list2' => to_h( context ) }
        ],
        49
      )
    end
    def show( context )
      if context.request.uri_path_components[ 0 ] == 'return_error'
        context.response.add_error(
          'generic.invalid_string',
          :message => 'Returning error as requested',
          :reference => { :another => 'no other ident', :field_name => 'no ident' }
        )
      elsif context.request.uri_path_components[ 0 ] == 'return_invalid_json'
        context.response.body = 'Hello, world'
      else
        context.response.body = { 'show' => to_h( context ) }
      end
    end
    def create( context )
      context.response.set_resource( { 'create' => to_h( context ) } )
    end
    def update( context )
      context.response.body = { 'update' => to_h( context ) }
    end
    def delete( context )
      context.response.body = { 'delete' => to_h( context ) }
    end

  private

    def to_h( context )
      {
        'locale'              => context.request.locale,
        'dated_at'            => context.request.dated_at.to_s,
        'body'                => context.request.body,
        'uri_path_components' => context.request.uri_path_components,
        'uri_path_extension'  => context.request.uri_path_extension,
        'list_offset'         => context.request.list.offset,
        'list_limit'          => context.request.list.limit,
        'list_sort_data'      => context.request.list.sort_data,
        'list_search_data'    => context.request.list.search_data,
        'list_filter_data'    => context.request.list.filter_data,
        'embeds'              => context.request.embeds,
        'references'          => context.request.references
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
      context.response.body = { 'show' => to_h( context ) }
    end

    def list( context )
      expectable_hook( context )
      context.response.set_resources( [ context.request.headers ], 1 )
    end

  private

    def to_h( context )
      {
        'locale'              => context.request.locale,
        'dated_at'            => context.request.dated_at.to_s,
        'body'                => context.request.body,
        'uri_path_components' => context.request.uri_path_components,
        'uri_path_extension'  => context.request.uri_path_extension,
        'list_offset'         => context.request.list.offset,
        'list_limit'          => context.request.list.limit,
        'list_sort_data'      => context.request.list.sort_data,
        'list_search_data'    => context.request.list.search_data,
        'list_filter_data'    => context.request.list.filter_data,
        'embeds'              => context.request.embeds,
        'references'          => context.request.references
      }
    end

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

    return if result.adds_errors_to?( context.response.errors )

    context.response.set_resources(
      [
        { 'listA' => result },
        { 'listB' => result },
        { 'listC' => result }
      ],
      ( result.dataset_size || 0 ) + 2
    )
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

      result = resource.show(
        context.request.uri_path_components.join( ',' ),
        {
          '_embed'     => context.request.embeds,
          '_reference' => context.request.references
        }
      )

      context.response.add_errors( result.platform_errors )
      context.response.body = { 'show' => result }

    end
  end

  def create( context )
    resource = context.resource( :TestEcho, 2 )
    result   = resource.create(
      context.request.body,
      {
        '_embed'     => context.request.embeds,
        '_reference' => context.request.references
      }
    )
    context.response.add_errors( result.platform_errors )
    context.response.body = { 'create' => result }
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
    context.response.add_errors( result.platform_errors )
    context.response.body = { 'update' => result }
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
    context.response.add_errors( result.platform_errors )
    context.response.body = { 'delete' => result }
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

# And Finally - the tests.

describe 'DRb start timeout' do
  context 'for test coverage purposes' do
    it 'checks for timeouts' do
      expect( DRbObject ).to receive( :new_with_uri ).once.and_raise( DRb::DRbConnError )
      expect( DRbObject ).to receive( :new_with_uri ).at_least( :once ).and_raise( Timeout::Error )

      spec_helper_http(
        port: spec_helper_start_svc_app_in_thread_for( TestEchoService ),
        path: '/v2/test_some_echoes'
      )
    end
  end
end
describe Hoodoo::Services::Middleware do

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

    def list_things( locale = nil, dated_at = nil )
      headers = {}
      headers[ 'Accept-Language' ] = locale unless locale.nil?
      headers[ 'X-Dated-At'      ] = Hoodoo::Utilities.nanosecond_iso8601( dated_at ) unless dated_at.nil?

      response = spec_helper_http(
        port:    @port,
        path:    '/v2/test_some_echoes.tar.gz?limit=25&offset=75&_reference=embed_one,embed_two',
        headers: headers
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ '_data' ]).to_not be_nil
      expect( parsed[ '_data' ][ 0 ]).to_not be_nil
      expect( parsed[ '_data' ][ 0 ][ 'list0' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'body'                => nil,
          'uri_path_components' => [],
          'uri_path_extension'  => 'tar.gz',
          'list_offset'         => 75,
          'list_limit'          => 25,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [ 'embed_one', 'embed_two' ]
        }
      )
      expect( parsed[ '_dataset_size' ] ).to eq( 49 )
    end

    it 'lists things with callbacks', :check_callbacks => true do
      list_things()
    end

    it 'list things without callbacks' do
      list_things()
    end

    it 'lists things with a custom locale and dated-at time' do
      list_things( 'foo', DateTime.now )
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
        path: '/v1/test_echo_quiet'
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ '_data' ] ).to eq( [ {
        'CONTENT_TYPE'    => 'application/json; charset=utf-8',
        'HTTP_CONNECTION' => 'close',
        'HTTP_VERSION'    => 'HTTP/1.1',
        'HTTP_HOST'       => "127.0.0.1:#{ @port }"
      } ] )
    end

    def show_things( locale = nil, dated_at = nil )
      headers = {}
      headers[ 'Accept-Language' ] = locale unless locale.nil?
      headers[ 'X-Dated-At'      ] = Hoodoo::Utilities.nanosecond_iso8601( dated_at ) unless dated_at.nil?

      response = spec_helper_http(
        port:    @port,
        path:    '/v2/test_some_echoes/one/two.tar.gz?_reference=embed_one,embed_two',
        headers: headers
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ 'show' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'body'                => nil,
          'uri_path_components' => [ 'one', 'two' ],
          'uri_path_extension'  => 'tar.gz',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [ 'embed_one', 'embed_two' ]
        }
      )
    end

    it 'shows_things_with_callbacks', :check_callbacks => true do
      show_things( 'fr' )
    end

    it 'shows_things_without_callbacks' do
      show_things( 'en' )
    end

    it 'shows things with a custom locale and dated-at time' do
      show_things( 'bar', DateTime.now )
    end

    it 'should be able to show quiet things too', :check_quiet_callbacks => true do

      response = spec_helper_http(
        port: @port,
        path: '/v1/test_echo_quiet/some_uuid'
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ 'show' ] ).to eq(
        {
          'locale'              => 'en-nz',
          'dated_at'            => '',
          'body'                => nil,
          'uri_path_components' => [ 'some_uuid' ],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => []
        }
      )
    end

    def create_things( locale = nil, dated_at = nil )
      headers = {}
      headers[ 'Accept-Language' ] = locale unless locale.nil?
      headers[ 'X-Dated-At'      ] = Hoodoo::Utilities.nanosecond_iso8601( dated_at ) unless dated_at.nil?

      response = spec_helper_http(
        klass:   Net::HTTP::Post,
        port:    @port,
        path:    '/v2/test_some_echoes.json?_embed=embed_one,embed_two',
        body:    { 'foo' => 'bar', 'baz' => 'boo' }.to_json,
        headers: headers
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ 'create' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'body'                => { 'foo' => 'bar', 'baz' => 'boo' },
          'uri_path_components' => [],
          'uri_path_extension'  => 'json',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [ 'embed_one', 'embed_two' ],
          'references'          => []
        }
      )
    end

    it 'creates things with callbacks', :check_callbacks => true do
      create_things()
    end

    it 'creates things without callbacks' do
      create_things()
    end

    it 'creates things with a custom locale and passes through dated-at' do
      create_things( 'baz', DateTime.now )
    end

    def update_things( locale = nil, dated_at = nil )
      headers = {}
      headers[ 'Accept-Language' ] = locale unless locale.nil?
      headers[ 'X-Dated-At'      ] = Hoodoo::Utilities.nanosecond_iso8601( dated_at ) unless dated_at.nil?

      response = spec_helper_http(
        klass:   Net::HTTP::Patch,
        port:    @port,
        path:    '/v2/test_some_echoes/a/b.json?_embed=embed_one',
        body:    { 'foo' => 'boo', 'baz' => 'bar' }.to_json,
        headers: headers
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ 'update' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'body'                => { 'foo' => 'boo', 'baz' => 'bar' },
          'uri_path_components' => [ 'a', 'b' ],
          'uri_path_extension'  => 'json',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [ 'embed_one' ],
          'references'          => []
        }
      )
    end

    it 'updates things with callbacks', :check_callbacks => true do
      update_things()
    end

    it 'updates things without callbacks' do
      update_things()
    end

    it 'updates things with a custom locale and passes through dated-at' do
      update_things( 'boo', DateTime.now )
    end

    def delete_things( locale = nil, dated_at = nil )
      headers = {}
      headers[ 'Accept-Language' ] = locale unless locale.nil?
      headers[ 'X-Dated-At'      ] = Hoodoo::Utilities.nanosecond_iso8601( dated_at ) unless dated_at.nil?

      response = spec_helper_http(
        klass:   Net::HTTP::Delete,
        port:    @port,
        path:    '/v2/test_some_echoes/aa/bb.xml.gz?_embed=embed_two',
        headers: headers
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ 'delete' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'body'                => nil,
          'uri_path_components' => [ 'aa', 'bb' ],
          'uri_path_extension'  => 'xml.gz',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [ 'embed_two' ],
          'references'          => []
        }
      )
    end

    it 'deletes things with callbacks', :check_callbacks => true do
      delete_things()
    end

    it 'deletes things without callbacks' do
      delete_things()
    end

    it 'deletes things, passing through custom locale and dated-at' do
      delete_things( 'bye', DateTime.now )
    end

    it 'should get 405 for bad requests' do

      # Attempt a #create (POST with body data) - service only does "show"
      # and "list".

      response = spec_helper_http(
        klass: Net::HTTP::Post,
        port:  @port,
        path:  '/v1/test_echo_quiet',
        body:  { 'foo' => 'bar', 'baz' => 'boo' }.to_json
      )

      expect( response.code ).to eq( '405' )
    end

    it 'should be detect 404 OK' do
      response = spec_helper_http(
        port: @port,
        path: '/v1/not_present'
      )

      expect( response.code ).to eq( '404' )
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

    def headers_for( locale, dated_at )
      headers = {
        'CONTENT_TYPE' => 'application/json; charset=utf-8'
      }

      # This arguably should be "Accept-Language" for reading vs
      # "Content-Language" for writing, but Hoodoo just reads either
      # regardless so we don't need to worry for the tests here.

      headers[ 'HTTP_ACCEPT_LANGUAGE' ] = locale unless locale.nil?
      headers[ 'HTTP_X_DATED_AT'      ] = Hoodoo::Utilities.nanosecond_iso8601( dated_at ) unless dated_at.nil?

      return headers
    end

    def list_things( locale = nil, dated_at = nil )
      get(
        '/v1/test_call.tar.gz?limit=25&offset=75',
        nil,
        headers_for( locale, dated_at )
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
          'body'                => nil,
          'uri_path_components' => [],
          'uri_path_extension'  => '',
          'list_offset'         => 75,
          'list_limit'          => 25,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => []
        }
      )
      expect( parsed[ '_dataset_size' ]).to eq( 51 )
    end

    it 'list things in the remote service with callbacks', :check_callbacks => true do
      list_things()
    end

    it 'list things in the remote service without callbacks' do
      list_things()
    end

    it 'lists things with a custom locale and dated-at time' do
      list_things( 'foo', DateTime.now )
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
        '/v1/test_call.tar.gz?limit=25&offset=75',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8',
          'HTTP_CONTENT_LANGUAGE' => 'de' }
      )

      module JSON
        class << self
          alias parse original_parse
        end
      end

      expect( last_response.status ).to eq( 500 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'errors' ][ 0 ][ 'message' ] ).to eq( "Hoodoo::Services::Middleware: Incompatible JSON implementation in use which doesn't understand 'object_class' or 'array_class' options" )
    end

    def show_things( locale = nil, dated_at = nil )
      get(
        '/v1/test_call/one/two.tar.gz',
        nil,
        headers_for( locale, dated_at )
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'show' ]).to_not be_nil
      expect( parsed[ 'show' ][ 'show' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'body'                => nil,
          'uri_path_components' => [ 'one,two' ],
          'uri_path_extension'  => '', # This is the *inner* inter-resource call's state and no filename extensions are used internally
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => []
        }
      )
    end

    it 'shows things in the remote service with callbacks', :check_callbacks => true do
      show_things()
    end

    it 'shows things in the remote service without callbacks' do
      show_things()
    end

    it 'shows things with a custom locale and dated-at time' do
      show_things( 'bar', DateTime.now )
    end

    def create_things( locale = nil, dated_at = nil )
      post(
        '/v1/test_call.tar.gz',
        { 'foo' => 'bar', 'baz' => 'boo' }.to_json,
        headers_for( locale, dated_at )
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'create' ]).to_not be_nil
      expect( parsed[ 'create' ][ 'create' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'body'                => { 'foo' => 'bar', 'baz' => 'boo' },
          'uri_path_components' => [],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => []
        }
      )
    end

    it 'creates things in the remote service with callbacks', :check_callbacks => true do
      create_things()
    end

    it 'creates things in the remote service without callbacks' do
      create_things()
    end

    it 'creates things with a custom locale and passes through dated-at' do
      create_things( 'baz', DateTime.now )
    end

    def update_things( locale = nil, dated_at = nil )
      patch(
        '/v1/test_call/aa/bb.tar.gz',
        { 'foo' => 'boo', 'baz' => 'bar' }.to_json,
        headers_for( locale, dated_at )
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'update' ]).to_not be_nil
      expect( parsed[ 'update' ][ 'update' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'body'                => { 'foo' => 'boo', 'baz' => 'bar' },
          'uri_path_components' => [ 'aa,bb' ],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => []
        }
      )
    end

    it 'updates things in the remote service with callbacks', :check_callbacks => true do
      update_things()
    end

    it 'updates things in the remote service without callbacks' do
      update_things()
    end

    it 'updates things with a custom locale and passes through dated-at' do
      update_things( 'boo', DateTime.now )
    end

    def delete_things( locale = nil, dated_at = nil )
      delete(
        '/v1/test_call/aone/btwo.tar.gz',
        nil,
        headers_for( locale, dated_at )
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'delete' ]).to_not be_nil
      expect( parsed[ 'delete' ][ 'delete' ] ).to eq(
        {
          'locale'              => locale.nil? ? 'en-nz' : locale,
          'dated_at'            => dated_at.to_s,
          'body'                => nil,
          'uri_path_components' => [ 'aone,btwo' ],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_data'      => { 'created_at' => 'desc' },
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => []
        }
      )
    end

    it 'deletes things in the remote service with callbacks', :check_callbacks => true do
      delete_things()
    end

    it 'deletes things in the remote service without callbacks' do
      delete_things()
    end

    it 'deletes things, passing through custom locale and dated-at' do
      delete_things( 'bye', DateTime.now )
    end

    it 'should receive errors from remote service as if from the local call' do
      get(
        '/v1/test_call/return_error',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 422 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'errors' ] ).to_not be_nil
      expect( parsed[ 'errors' ].count ).to eq(1)
      expect( parsed[ 'errors' ][ 0 ] ).to eq({
        'code'      => 'generic.invalid_string',
        'message'   => 'Returning error as requested',
        'reference' => 'no ident,no other ident'
      })
    end

    it 'gets a 404 for missing endpoints' do
      get(
        '/v1/test_call/generate_404',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 404 )
    end

    it 'can reuse an endpoint' do
      get(
        '/v1/test_call/ensure_repeated_use_works',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'show' ]).to_not be_nil
      expect( parsed[ 'show' ][ 'show' ][ 'uri_path_components' ] ).to eq( [ 'ensure_repeated_use_works' ] )
    end

    # Ruby can't kill off an "unresponsive" thread - there seems to be no
    # equivalent of "kill -9" and the likes of "#exit!" are long gone - so
    # the WEBrick server thread, which never returns to the Ruby interpreter
    # after the Rack::Server.start() call (or equivalent) can't die. Instead
    # we are forced to write a fragile test that simulates a connection
    # failure to the endpoint.
    #
    it 'should get a 404 for no-longer-running endpoints' do
      expect_any_instance_of( Net::HTTP ).to receive( :request ).once.and_raise( Errno::ECONNREFUSED )

      get(
        '/v1/test_call/show_something',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 404 )
    end

    # Similarly shaky test for simulating arbitrary other failure kinds.
    #
    it 'should get a 500 for arbitrary failures' do
      expect_any_instance_of( Net::HTTP ).to receive( :request ).once.and_raise( 'some connection error' )

      get(
        '/v1/test_call/show_something',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 500 )
      expect( last_response.body ).to include( 'some connection error' )
    end
  end
end
