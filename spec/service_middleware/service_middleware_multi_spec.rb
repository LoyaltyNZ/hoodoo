# service_middleware_spec.rb is too large and this set of tests is weird
# anyway - we want to test inter-service remote calls, so we start multiple
# HTTP server instances in threads and have them talk to each other.

require 'spec_helper'

# First, a test service comprised of a couple of 'echo' variants which we use
# to make sure they're both correctly stored in the DRb registry.

class TestEchoServiceImplementation < ApiTools::ServiceImplementation

  public

    def list( context )
      context.response.body = { 'list' => to_h( context ) }
    end
    def show( context )
      context.response.body = { 'show' => to_h( context ) }
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
        'list_offset'         => context.request.list_offset,
        'list_limit'          => context.request.list_limit,
        'list_sort_key'       => context.request.list_sort_key,
        'list_sort_direction' => context.request.list_sort_direction,
        'list_search_data'    => context.request.list_search_data,
        'list_filter_data'    => context.request.list_filter_data,
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
        'list_offset'         => context.request.list_offset,
        'list_limit'          => context.request.list_limit,
        'list_sort_key'       => context.request.list_sort_key,
        'list_sort_direction' => context.request.list_sort_direction,
        'list_search_data'    => context.request.list_search_data,
        'list_filter_data'    => context.request.list_filter_data,
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
        'offset'     => context.request.list_offset,
        'limit'      => context.request.list_limit,
        'sort'       => context.request.list_sort_key,
        'direction'  => context.request.list_sort_direction,
        'search'     => context.request.list_search_data,
        'filter'     => context.request.list_filter_data,
        '_embed'     => context.request.embeds,
        '_reference' => context.request.references
      }
    )
    context.response.body = { 'list' => result }
  end
  def show( context )
    context.response.body = { 'show' => result }
  end
  def create( context )
    context.response.body = { 'create' => result }
  end
  def update( context )
    context.response.body = { 'update' => result }
  end
  def delete( context )
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

# Find a spare (unused / closed) port on 127.0.0.1
# http://stackoverflow.com/questions/5985822/how-do-you-find-a-random-open-port-in-ruby

require 'socket'

def find_unused_port
  socket = Socket.new( :INET, :STREAM, 0 )
  socket.bind( Addrinfo.tcp( '127.0.0.1', 0 ) )
  port = socket.local_address.ip_port
  socket.close
  return port
end

# Make an HTTP request using the given class to the given path (string, with
# query string if you want one) with optional extra headers (as a name/value
# Hash) and body data (as a String containing JSON data).

def run_request( klass, path, body = nil, headers = {} )
  headers    = { 'Content-Type' => 'application/json; charset=utf-8' }.merge( headers )
  remote_uri = URI.parse( "http://127.0.0.1:#{ @port }/#{ path }" )
  http       = Net::HTTP.new( remote_uri.host, remote_uri.port )
  request    = klass.new( remote_uri.request_uri() )

  request.initialize_http_header( headers )
  request.body = body unless body.nil?

  return http.request( request )
end

# And Finally - the tests.

describe ApiTools::ServiceMiddleware do

  before :all do

    # Bring up the web server running the echo service inside @thread.

    @port   = find_unused_port()
    @thread = Thread.start do
      app = Rack::Builder.new do
        use ApiTools::ServiceMiddleware
        run TestEchoServiceApplication.new
      end

      # This command never returns. Since this server brings up the echo
      # service application before anything else happens, this is the
      # application which will also run the DRb server.

      Rack::Server.start(
        :app  => app,
        :Host => '127.0.0.1',
        :Port => @port,
        :server => :webrick
      )
    end

    # Wait for the server to come up. I tried many approaches. In the end,
    # only this hacky polling-talk-to-server code worked reliably.

    repeat = true

    while repeat
      begin
        run_request(Net::HTTP::Get, '')
        repeat = false
      rescue Errno::ECONNREFUSED
        sleep 0.1
      end
    end
  end

  # Although tests can run in random order so we can't force this set to come
  # first, at least having this set present validates all of the HTTP behaviour
  # we expect to work in the echo service. If these tests fail, all bets are
  # off for anything else tested here.
  #
  context 'with in-thread HTTP service' do

    it 'should be able to list things' do
      response = run_request(
        Net::HTTP::Get,
        'v2/test_some_echoes.tar.gz?limit=25&offset=75&_reference=embed_one,embed_two'
      )

      expect( response.code ).to eq( '200' )
      parsed = JSON.parse( response.body )

      expect( parsed[ 'list' ] ).to eq(
        {
          'locale'              => 'en-nz',
          'body'                => nil,
          'uri_path_components' => [],
          'uri_path_extension'  => 'tar.gz',
          'list_offset'         => 75,
          'list_limit'          => 25,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
          'list_search_data'    => nil,
          'list_filter_data'    => nil,
          'embeds'              => nil,
          'references'          => [ 'embed_one', 'embed_two' ]
        }
      )
    end

    it 'should be able to show things' do
      response = run_request(
        Net::HTTP::Get,
        'v2/test_some_echoes/one/two.tar.gz?_reference=embed_one,embed_two',
        nil,
        { 'Content-Language' => 'fr' }
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
          'list_search_data'    => nil,
          'list_filter_data'    => nil,
          'embeds'              => nil,
          'references'          => [ 'embed_one', 'embed_two' ]
        }
      )
    end

    it 'should be able to show quiet things too' do
      response = run_request(
        Net::HTTP::Get,
        'v1/test_echo_quiet/some_uuid'
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
          'list_search_data'    => nil,
          'list_filter_data'    => nil,
          'embeds'              => nil,
          'references'          => nil
        }
      )
    end

    it 'should be able to create things' do
      response = run_request(
        Net::HTTP::Post,
        'v2/test_some_echoes.json?_embed=embed_one,embed_two',
        { 'foo' => 'bar', 'baz' => 'boo' }.to_json
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
          'list_search_data'    => nil,
          'list_filter_data'    => nil,
          'embeds'              => [ 'embed_one', 'embed_two' ],
          'references'          => nil
        }
      )
    end

    it 'should be able to update things' do
      response = run_request(
        Net::HTTP::Patch,
        'v2/test_some_echoes/a/b.json?_embed=embed_one',
        { 'foo' => 'boo', 'baz' => 'bar' }.to_json,
        { 'Content-Language' => 'de' }
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
          'list_search_data'    => nil,
          'list_filter_data'    => nil,
          'embeds'              => [ 'embed_one' ],
          'references'          => nil
        }
      )
    end

    it 'should be able to delete things' do
      response = run_request(
        Net::HTTP::Delete,
        'v2/test_some_echoes/aa/bb.xml.gz?_embed=embed_two'
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
          'list_search_data'    => nil,
          'list_filter_data'    => nil,
          'embeds'              => [ 'embed_two' ],
          'references'          => nil
        }
      )
    end

    it 'should get 422 for bad requests' do
      response = run_request(
        Net::HTTP::Get,
        'v1/test_echo_quiet' # I.e. "list" action, but service only does "show"
      )

      expect( response.code ).to eq( '422' )
    end

    it 'should be detect 404 OK' do
      response = run_request(
        Net::HTTP::Get,
        'v1/not_present'
      )

      expect( response.code ).to eq( '404' )
    end
  end

  #############################################################################

  context 'remote inter-service calls' do
    def app
      Rack::Builder.new do
        use ApiTools::ServiceMiddleware
        run TestCallServiceApplication.new
      end
    end

    it 'should be able to list things in the remote service' do
      get(
        '/v1/test_call.tar.gz?limit=25&offset=75',
        nil,
        { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
      )

      expect( last_response.status ).to eq( 200 )
      parsed = JSON.parse( last_response.body )

      expect( parsed[ 'list' ][ 'list' ] ).to eq(
        {
          'locale'              => 'en-nz',
          'body'                => nil,
          'uri_path_components' => [],
          'uri_path_extension'  => '',
          'list_offset'         => 75,
          'list_limit'          => 25,
          'list_sort_key'       => 'created_at',
          'list_sort_direction' => 'desc',
          'list_search_data'    => nil,
          'list_filter_data'    => nil,
          'embeds'              => nil,
          'references'          => nil
        }
      )
    end
  end
end
