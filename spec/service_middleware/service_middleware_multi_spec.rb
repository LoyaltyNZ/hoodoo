# service_middleware_spec.rb is too large and this set of tests is weird
# anyway - we want to test inter-resource remote calls, so we start multiple
# HTTP server instances in threads and have them talk to each other.

require 'spec_helper'
require 'json'

# First, a test service comprised of a couple of 'echo' variants which we use
# to make sure they're both correctly stored in the DRb registry.

class TestEchoServiceImplementation < ApiTools::ServiceImplementation

  public

    def list( context )
      context.response.body = [
         { 'list0' => to_h( context ) },
         { 'list1' => to_h( context ) },
         { 'list2' => to_h( context ) }
      ]
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
      context.response.body = { 'create' => to_h( context ) }
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
        'body'                => context.request.body,
        'uri_path_components' => context.request.uri_path_components,
        'uri_path_extension'  => context.request.uri_path_extension,
        'list_offset'         => context.request.list.offset,
        'list_limit'          => context.request.list.limit,
        'list_sort_key'       => context.request.list.sort_key,
        'list_sort_direction' => context.request.list.sort_direction,
        'list_search_data'    => context.request.list.search_data,
        'list_filter_data'    => context.request.list.filter_data,
        'embeds'              => context.request.embeds,
        'references'          => context.request.references
      }
    end
end

class TestEchoServiceInterface < ApiTools::ServiceInterface
  interface :TestEcho do
    version 2
    endpoint :test_some_echoes, TestEchoServiceImplementation

    embeds :embed_one, :embed_two

    to_list do
      search :search_one, :search_two
      filter :filter_one, :filter_two
    end
  end
end

class TestEchoQuietServiceImplementation < ApiTools::ServiceImplementation

  public

    def show( context )
      context.response.body = { 'show' => to_h( context ) }
    end

  private

    def to_h( context )
      {
        'locale'              => context.request.locale,
        'body'                => context.request.body,
        'uri_path_components' => context.request.uri_path_components,
        'uri_path_extension'  => context.request.uri_path_extension,
        'list_offset'         => context.request.list.offset,
        'list_limit'          => context.request.list.limit,
        'list_sort_key'       => context.request.list.sort_key,
        'list_sort_direction' => context.request.list.sort_direction,
        'list_search_data'    => context.request.list.search_data,
        'list_filter_data'    => context.request.list.filter_data,
        'embeds'              => context.request.embeds,
        'references'          => context.request.references
      }
    end
end

class TestEchoQuietServiceInterface < ApiTools::ServiceInterface
  interface :TestEchoQuiet do
    endpoint :test_echo_quiet, TestEchoQuietServiceImplementation
    actions :show
  end
end

class TestEchoServiceApplication < ApiTools::ServiceApplication
  comprised_of TestEchoServiceInterface, TestEchoQuietServiceInterface
end

# Now the calling service that'll call over to the echo services above.

class TestCallServiceImplementation < ApiTools::ServiceImplementation
  def list( context )
    resource = context.resource( :TestEcho, 2 )
    result   = resource.list(
      {
        'offset'     => context.request.list.offset,
        'limit'      => context.request.list.limit,
        'sort'       => context.request.list.sort_key,
        'direction'  => context.request.list.sort_direction,
        'search'     => context.request.list.search_data,
        'filter'     => context.request.list.filter_data,
        '_embed'     => context.request.embeds,
        '_reference' => context.request.references
      }
    )
    context.response.body = [
      { 'listA' => result },
      { 'listB' => result },
      { 'listC' => result }
    ]
  end

  def show( context )
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

  def create( context )
    resource = context.resource( :TestEcho, 2 )
    result   = resource.create(
      context.request.body,
      {
        '_embed'     => context.request.embeds,
        '_reference' => context.request.references
      }
    )
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
    context.response.body = { 'delete' => result }
  end
end

class TestCallServiceInterface < ApiTools::ServiceInterface
  interface :TestCall do
    endpoint :test_call, TestCallServiceImplementation
  end
end

class TestCallServiceApplication < ApiTools::ServiceApplication
  comprised_of TestCallServiceInterface
end

# And Finally - the tests.

describe ApiTools::ServiceMiddleware do

  before :all do
    @port = spec_helper_start_svc_app_in_thread_for( TestEchoServiceApplication )
  end

  # Although tests can run in random order so we can't force this set to come
  # first, at least having this set present validates all of the HTTP behaviour
  # we expect to work in the echo service. If these tests fail, all bets are
  # off for anything else tested here.
  #
  context 'with in-thread HTTP service' do

    before :example, :check_callbacks => true do
      expect_any_instance_of( TestEchoServiceImplementation ).to receive( :before ).once
      expect_any_instance_of( TestEchoServiceImplementation ).to receive( :after ).once
    end

    before :example, :check_quiet_callbacks => true do
      expect_any_instance_of( TestEchoQuietServiceImplementation ).to receive( :before ).once
      expect_any_instance_of( TestEchoQuietServiceImplementation ).to receive( :after ).once
    end

    def list_things
      response = spec_helper_http(
        port: @port,
        path: '/v2/test_some_echoes.tar.gz?limit=25&offset=75&_reference=embed_one,embed_two'
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ '_data' ]).to_not be_nil
      expect( parsed[ '_data' ][ 0 ]).to_not be_nil
      expect( parsed[ '_data' ][ 0 ][ 'list0' ] ).to eq(
        {
          'locale'              => 'en-nz',
          'body'                => nil,
          'uri_path_components' => [],
          'uri_path_extension'  => 'tar.gz',
          'list_offset'         => 75,
          'list_limit'          => 25,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [ 'embed_one', 'embed_two' ]
        }
      )
    end

    it 'lists things with callbacks', :check_callbacks => true do
      list_things()
    end

    it 'list things without callbacks' do
      list_things()
    end

    def show_things
      response = spec_helper_http(
        port:    @port,
        path:    '/v2/test_some_echoes/one/two.tar.gz?_reference=embed_one,embed_two',
        headers: { 'Content-Language' => 'fr' }
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ 'show' ] ).to eq(
        {
          'locale'              => 'fr',
          'body'                => nil,
          'uri_path_components' => [ 'one', 'two' ],
          'uri_path_extension'  => 'tar.gz',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => [ 'embed_one', 'embed_two' ]
        }
      )
    end

    it 'shows_things_with_callbacks', :check_callbacks => true do
      show_things()
    end

    it 'shows_things_without_callbacks' do
      show_things()
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
          'body'                => nil,
          'uri_path_components' => [ 'some_uuid' ],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => []
        }
      )
    end

    def create_things
      response = spec_helper_http(
        klass: Net::HTTP::Post,
        port:  @port,
        path:  '/v2/test_some_echoes.json?_embed=embed_one,embed_two',
        body:  { 'foo' => 'bar', 'baz' => 'boo' }.to_json
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ 'create' ] ).to eq(
        {
          'locale'              => 'en-nz',
          'body'                => { 'foo' => 'bar', 'baz' => 'boo' },
          'uri_path_components' => [],
          'uri_path_extension'  => 'json',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
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

    def update_things
      response = spec_helper_http(
        klass:   Net::HTTP::Patch,
        port:    @port,
        path:    '/v2/test_some_echoes/a/b.json?_embed=embed_one',
        body:    { 'foo' => 'boo', 'baz' => 'bar' }.to_json,
        headers: { 'Content-Language' => 'de' }
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ 'update' ] ).to eq(
        {
          'locale'              => 'de',
          'body'                => { 'foo' => 'boo', 'baz' => 'bar' },
          'uri_path_components' => [ 'a', 'b' ],
          'uri_path_extension'  => 'json',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
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

    def delete_things
      response = spec_helper_http(
        klass: Net::HTTP::Delete,
        port:  @port,
        path:  '/v2/test_some_echoes/aa/bb.xml.gz?_embed=embed_two'
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ 'delete' ] ).to eq(
        {
          'locale'              => 'en-nz',
          'body'                => nil,
          'uri_path_components' => [ 'aa', 'bb' ],
          'uri_path_extension'  => 'xml.gz',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
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

    it 'should get 405 for bad requests' do
      response = spec_helper_http(
        port: @port,
        path: '/v1/test_echo_quiet' # I.e. "list" action, but service only does "show"
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
        use ApiTools::ServiceMiddleware
        run TestCallServiceApplication.new
      end
    end

    before :example, :check_callbacks => true do
      expect_any_instance_of( TestCallServiceImplementation ).to receive( :before ).once
        expect_any_instance_of( TestEchoServiceImplementation ).to receive( :before ).once
        expect_any_instance_of( TestEchoServiceImplementation ).to receive( :after ).once
      expect_any_instance_of( TestCallServiceImplementation ).to receive( :after ).once
    end

    def list_things
      get(
        '/v1/test_call.tar.gz?limit=25&offset=75',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8',
          'HTTP_CONTENT_LANGUAGE' => 'de' }
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
          'locale'              => 'de',
          'body'                => nil,
          'uri_path_components' => [],
          'uri_path_extension'  => '',
          'list_offset'         => 75,
          'list_limit'          => 25,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
          'list_search_data'    => {},
          'list_filter_data'    => {},
          'embeds'              => [],
          'references'          => []
        }
      )
    end

    it 'list things in the remote service with callbacks', :check_callbacks => true do
      list_things()
    end

    it 'list things in the remote service without callbacks' do
      list_things()
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

      expect( parsed[ 'errors' ][ 0 ][ 'message' ] ).to eq( "ApiTools::ServiceMiddleware: Incompatible JSON implementation in use which doesn't understand 'object_class' or 'array_class' options" )
    end

    def show_things
      get(
        '/v1/test_call/one/two.tar.gz',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'show' ]).to_not be_nil
      expect( parsed[ 'show' ][ 'show' ] ).to eq(
        {
          'locale'              => 'en-nz',
          'body'                => nil,
          'uri_path_components' => [ 'one,two' ],
          'uri_path_extension'  => '', # This is the *inner* inter-resource call's state and no filename extensions are used internally
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
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

    def create_things
      post(
        '/v1/test_call.tar.gz',
        { 'foo' => 'bar', 'baz' => 'boo' }.to_json,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'create' ]).to_not be_nil
      expect( parsed[ 'create' ][ 'create' ] ).to eq(
        {
          'locale'              => 'en-nz',
          'body'                => { 'foo' => 'bar', 'baz' => 'boo' },
          'uri_path_components' => [],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
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

    def update_things
      patch(
        '/v1/test_call/aa/bb.tar.gz',
        { 'foo' => 'boo', 'baz' => 'bar' }.to_json,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'update' ]).to_not be_nil
      expect( parsed[ 'update' ][ 'update' ] ).to eq(
        {
          'locale'              => 'en-nz',
          'body'                => { 'foo' => 'boo', 'baz' => 'bar' },
          'uri_path_components' => [ 'aa,bb' ],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
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

    def delete_things
      delete(
        '/v1/test_call/aone/btwo.tar.gz',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8',
          'HTTP_CONTENT_LANGUAGE' => 'fr' }
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'delete' ]).to_not be_nil
      expect( parsed[ 'delete' ][ 'delete' ] ).to eq(
        {
          'locale'              => 'fr',
          'body'                => nil,
          'uri_path_components' => [ 'aone,btwo' ],
          'uri_path_extension'  => '',
          'list_offset'         => 0,
          'list_limit'          => 50,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
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

    it 'should get a 404 for missing endpoints' do
      get(
        '/v1/test_call/generate_404',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 404 )
    end

    # Ruby can't kill off an "unresponsive" thread - there seems to be no
    # equivalent of "kill -9" and the likes of "#exit!" are long gone - so
    # the WEBrick server thread, which never returns to the Ruby interpreter
    # after the Rack::Server.start() call (or equivalent) can't die. Instead
    # we are forced to write a weak test that simulates a connection failure
    # to the endpoint.
    #
    it 'should get a 404 for no-longer-running endpoints' do
      expect_any_instance_of(Net::HTTP).to receive(:request).once.and_raise(Errno::ECONNREFUSED)

      get(
        '/v1/test_call/show_something',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 404 )
    end
  end
end
