# Specific tests for behaviour around the middleware's enforcement of
# the to_create/to_update DSL through service interfaces and validation
# of inbound payloads.
#
# Since it relies upon the same test setup, the X-Resource-UUID secured
# header is tested here - both secure headers as a mechanism, and that
# particular header allowing in a value for a resource ID which gets
# passed in as an "id" field in the effective body data.

require 'spec_helper.rb'

# Resource "A" describes different to-create/to-update data as a set
# of explicit declarations.

class RSpecToUpdateToCreateTestAImplementation < Hoodoo::Services::Implementation
  def create( context ); context.response.body = context.request.body; end
  def update( context ); context.response.body = context.request.body; end
end

class RSpecToUpdateToCreateTestAInterface < Hoodoo::Services::Interface
  interface :RSpecToUpdateToCreateTestA do
    endpoint :r_spec_to_update_to_create_test_a, RSpecToUpdateToCreateTestAImplementation

    # Default values in to-create blocks are irrelevant as they're for
    # rendering only. Expectations in tests for the hashes "seen" by
    # the mock resource implementations check this because the resources
    # return "context.response.body" as-is, so if default values were
    # leaked into that, tests would fail.

    to_create do
      text :foo
      integer :bar, :required => true
      integer :defaulted, :default => 42
      object :nested do
        text :thing
      end
    end

    # Required values in to-update blocks are ignored. There is explicit
    # test coverage for this. Default values are handled the same way as
    # with to-create.

    to_update do
      boolean :foo, :required => true
      enum :bar, :from => [ :foo, :bar, :baz ]
      integer :defaulted, :default => 24
      object :nested do
        text :thing
      end
    end
  end
end

# Resource "B" describes to-create/to-update data in terms of Hoodoo
# Resources and Types. Common resource fields like 'id', 'kind' etc.
# should still _not_ be permitted for inbound creation or updates.

class RSpecToUpdateToCreateTestBImplementation < Hoodoo::Services::Implementation
  def create( context ); context.response.body = context.request.body; end
  def update( context ); context.response.body = context.request.body; end
end

class RSpecToUpdateToCreateTestBInterface < Hoodoo::Services::Interface
  interface :RSpecToUpdateToCreateTestB do
    endpoint :r_spec_to_update_to_create_test_b, RSpecToUpdateToCreateTestBImplementation

    to_create do
      resource :Errors
      type :ErrorPrimitive
    end

    to_update do
      resource :Session
      type :Permissions
    end
  end
end

# Resource "C" describes nothing special, to check that common fields
# are still rejected for creations and updates.

class RSpecToUpdateToCreateTestCImplementation < Hoodoo::Services::Implementation
  def create( context ); context.response.body = context.request.body; end
  def update( context ); context.response.body = context.request.body; end
end

class RSpecToUpdateToCreateTestCInterface < Hoodoo::Services::Interface
  interface :RSpecToUpdateToCreateTestC do
    endpoint :r_spec_to_update_to_create_test_c, RSpecToUpdateToCreateTestCImplementation
  end
end

# Put them all in the same service application for simplicity.

class RSpecToUpdateToCreateTestService < Hoodoo::Services::Service
  comprised_of RSpecToUpdateToCreateTestAInterface,
               RSpecToUpdateToCreateTestBInterface

  # Paranoid implicit check that multiple "comprised_of" calls still work :-)

  comprised_of RSpecToUpdateToCreateTestCInterface
end

# Finally, the tests.

describe Hoodoo::Services::Middleware do
  def app
    Rack::Builder.new do
      use Hoodoo::Services::Middleware
      run RSpecToUpdateToCreateTestService.new
    end
  end

  def do_post( variant, hash, headers = {} ) # Variant is :a or :b
    post "/v1/r_spec_to_update_to_create_test_#{ variant }/",
         hash.nil? ? '' : JSON.generate( hash ),
         { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }.merge( headers )

    expectations( hash )
  end

  def do_patch( variant, hash, headers = {} ) # Variant is :a or :b
    patch "/v1/r_spec_to_update_to_create_test_#{ variant }/any",
          hash.nil? ? '' : JSON.generate( hash ),
          { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }.merge( headers )

    expectations( hash )
  end

  context 'accepts valid input' do
    def expectations( hash )
      expect( last_response.status ).to eq( 200 )
      expect( JSON.parse( last_response.body ) ).to eq( hash )
    end

    it 'with many fields' do
      do_post( :a, 'foo' => 'hello', 'bar' => 42 )
      do_patch( :a, 'foo' => true, 'bar' => 'foo' )
      do_post( :b, 'code' => 'hello', 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'actions' => { 'list' => 'allow' }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
    end

    it 'with required fields only' do
      do_post( :a, 'bar' => 42 )
      do_patch( :a, 'foo' => true )
      do_post( :b, 'code' => 'hello', 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
    end

    # Explicit nils should be preserved through rendering and
    # accepted through the checking engine (for non-required data).
    #
    it 'with explicit nils' do
      do_post( :a, 'foo' => nil, 'bar' => 42 )
      do_patch( :a, 'foo' => true, 'bar' => nil )
      do_post( :b, 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_patch( :b, 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
    end
  end

  context 'rejects unknown data' do
    def expectations( hash )
      expect( last_response.status ).to eq( 422 )
      parsed = JSON.parse( last_response.body )
      expect( parsed[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Body data contains unrecognised or prohibited fields' )
      expect( parsed[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'random' )
    end

    it 'with many fields' do
      do_post( :a, 'foo' => 'hello', 'bar' => 42, 'random' => true )
      do_patch( :a, 'foo' => true, 'bar' => 'foo', 'random' => true )
      do_post( :b, 'code' => 'hello', 'random' => true, 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'actions' => { 'list' => 'allow' }, 'random' => true, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
    end

    it 'with required fields only' do
      do_post( :a, 'bar' => 42, 'random' => true )
      do_patch( :a, 'foo' => true, 'random' => true )
      do_post( :b, 'code' => 'hello', 'random' => true, 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'random' => true, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
    end

    it 'with explicit nils' do
      do_post( :a, 'foo' => nil, 'bar' => 42, 'random' => true )
      do_patch( :a, 'foo' => true, 'bar' => nil, 'random' => true )
      do_post( :b, 'code' => 'hello', 'random' => true, 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'actions' => nil, 'random' => true, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_patch( :b, 'actions' => { 'list' => nil }, 'random' => true, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
    end

    it 'rejects unknown data across many fields (flat top level)' do
      def expectations( hash )
        expect( last_response.status ).to eq( 422 )
        parsed = JSON.parse( last_response.body )
        expect( parsed[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Body data contains unrecognised or prohibited fields' )
        expect( parsed[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'random\\, more' )
      end

      do_post( :a, 'foo' => 'hello', 'bar' => 42, 'random' => { 'foo' => true, 'bar' => true }, 'more' => 42 )
      do_patch( :a, 'foo' => true, 'bar' => 'foo', 'random' => { 'foo' => true, 'bar' => true }, 'more' => 42 )
    end

    it 'rejects unknown data across many fields (nested top level)' do
      def expectations( hash )
        expect( last_response.status ).to eq( 422 )
        parsed = JSON.parse( last_response.body )
        expect( parsed[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Body data contains unrecognised or prohibited fields' )
        expect( parsed[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'nested.foo\\, nested.bar\\, more' )
      end

      do_post( :a, 'foo' => 'hello', 'bar' => 42, 'nested' => { 'foo' => true, 'bar' => true }, 'more' => 42 )
      do_patch( :a, 'foo' => true, 'bar' => 'foo', 'nested' => { 'foo' => true, 'bar' => true }, 'more' => 42 )
    end
  end

  context 'rejects known but prohibited fields' do
    def expectations( hash )
      expect( last_response.status ).to eq( 422 )
      expect( JSON.parse( last_response.body )[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Body data contains unrecognised or prohibited fields' )
    end

    # Paranoia check to ensure rejection when attempting to specify just an ID,
    # with an otherwise entirely valid payload.
    #
    it 'for just "id"' do
      do_post( :a, { 'id' => Hoodoo::UUID.generate, 'foo' => 'hello', 'bar' => 42 } )
    end

    it 'with many fields' do
      do_post( :b,  'id' => Hoodoo::UUID.generate, 'code' => 'hello', 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'id' => Hoodoo::UUID.generate, 'actions' => { 'list' => 'allow' }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_post( :b,  'kind' => 'Foo', 'code' => 'hello', 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'kind' => 'Foo', 'actions' => { 'list' => 'allow' }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_post( :b,  'created_at' => Time.now.iso8601, 'code' => 'hello', 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'created_at' => Time.now.iso8601, 'actions' => { 'list' => 'allow' }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_post( :b,  'language' => 'fr', 'code' => 'hello', 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'language' => 'fr', 'actions' => { 'list' => 'allow' }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
    end

    it 'with required fields only' do
      do_post( :b,  'id' => Hoodoo::UUID.generate, 'code' => 'hello', 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'id' => Hoodoo::UUID.generate, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_post( :b,  'kind' => 'Foo', 'code' => 'hello', 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'kind' => 'Foo', 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_post( :b,  'created_at' => Time.now.iso8601, 'code' => 'hello', 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'created_at' => Time.now.iso8601, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_post( :b,  'language' => 'fr', 'code' => 'hello', 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'language' => 'fr', 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
    end

    it 'with explicit nils' do
      do_post( :b,  'id' => Hoodoo::UUID.generate, 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'id' => Hoodoo::UUID.generate, 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_patch( :b, 'id' => Hoodoo::UUID.generate, 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_post( :b,  'kind' => 'Foo', 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'kind' => 'Foo', 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_patch( :b, 'kind' => 'Foo', 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_post( :b,  'created_at' => Time.now.iso8601, 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'created_at' => Time.now.iso8601, 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_patch( :b, 'created_at' => Time.now.iso8601, 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_post( :b,  'language' => 'fr', 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'language' => 'fr', 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      do_patch( :b, 'language' => 'fr', 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
    end
  end

  # A more complete range of tests for the DSL is elsewhere, but it's easy
  # to add a bit more coverage here explicitly for the to-create/update code.

  context 'rejects known fields with incorrect types' do
    def expectations( hash )
      expect( last_response.status ).to eq( 422 )
    end

    it 'with many fields' do
      do_post( :a, 'foo' => 'hello', 'bar' => 'not an integer' )
      do_patch( :a, 'foo' => 'not boolean', 'bar' => 'foo' )
      do_post( :b, 'code' => 22, 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'actions' => 'not an object', 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
    end

    it 'with required fields only' do
      do_post( :a, 'bar' => 'still not an integer' )
      do_patch( :a, 'foo' => 'still not a boolean' )
      do_post( :b, 'code' => 'hello', 'message' => 'world', 'errors' => 'not an array' )
      do_patch( :b, 'caller_id' => 'not a uuid', 'expires_at' => Time.now.iso8601 )
    end

    it 'with explicit nils' do
      do_post( :a, 'foo' => nil, 'bar' => 'still not an integer' )
      do_patch( :a, 'foo' => 'still not a boolean', 'bar' => nil )
      do_post( :b, 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => 'still not an array' )
      do_patch( :b, 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => 'not a time' )
      do_patch( :b, 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => 'not a time' )
    end
  end

  # Reject common fields where there's no create/update block.

  context 'rejects common fields without schema' do
    def expectations( ignore )
      expect( last_response.status ).to eq( 422 )
      parsed = JSON.parse( last_response.body )
      expect( parsed[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Body data contains unrecognised or prohibited fields' )
      expect( parsed[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'id\\, created_at\\, kind\\, language' )
    end

    it 'rejects bad creations' do
      do_post( :c, 'created_at' => 'now', 'id' => '234',
                   'kind' => 'FortyTwo', 'language' => 'bleat',
                   'random' => 'field' )
    end

    it 'rejects bad updates' do
      do_patch( :c, 'created_at' => 'now', 'id' => '234',
                    'kind' => 'FortyTwo', 'language' => 'bleat',
                    'random' => 'field' )
    end
  end

  # There's coverage for ":required => true" elsewhere too, but again,
  # may as well add extra coverage for to-create/to-update here.
  #
  # The creation blocks expect to fault the missing required fields with
  # a 422. The update blocks expect this to be OK (omitted field just
  # means "don't change the value").
  #
  context 'required fields' do
    context 'are required for to_create' do
      def expectations( hash )
        expect( last_response.status ).to eq( 422 )
        expect( JSON.parse( last_response.body )[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'generic.required_field_missing' )
      end

      it 'with many fields' do
        do_post( :a, 'foo' => 'hello' )
        do_post( :b, 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      end

      it 'with empty data' do
        do_post( :a, {} )
        do_post( :b, {} )
      end

      it 'with explicit nils' do
        do_post( :a, 'bar' => nil )
        do_post( :b, 'code' => nil, 'message' => 'world', 'reference' => nil, 'errors' => [] )
      end
    end

    context 'are irrelevant for to_update' do
      def expectations( hash )
        expect( last_response.status ).to eq( 200 )
      end

      it 'with many fields' do
        do_patch( :a, 'bar' => 'foo' )
        do_patch( :b, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      end

      it 'with empty data' do
        do_patch( :a, {} )
        do_patch( :b, {} )
      end

      it 'with explicit nils' do
        do_patch( :a, 'foo' => nil )
        do_patch( :b, 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
        do_patch( :b, 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601 )
      end
    end
  end

  # Tests for the X-Resource-UUID header / authorised headers generally.

  context 'with X-Resource-UUID' do
    before :each do
      @test_uuid = Hoodoo::UUID.generate()
      @old_test_session = Hoodoo::Services::Middleware.test_session()
      @test_session = @old_test_session.dup
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

    it 'accepts session-authorised and valid IDs' do
      def expectations( hash )
        expect( last_response.status ).to eq( 200 )
        expect( JSON.parse( last_response.body ) ).to eq( hash.merge( 'id' => @test_uuid ) )
      end

      @test_session.scoping.authorised_http_headers = [ 'HTTP_X_RESOURCE_UUID' ]
      do_post( :a, { 'foo' => 'hello', 'bar' => 42 }, { 'HTTP_X_RESOURCE_UUID' => @test_uuid } )
    end

    # Don't expect any errors for non-POST uses of X-Resource-UUID; just
    # don't expect the body data to contain the 'id' field.
    #
    it 'rejects session-authorised and valid IDs for PATCH' do
      def expectations( hash )
        expect( last_response.status ).to eq( 200 )
        expect( JSON.parse( last_response.body ) ).to eq( { 'foo' => true } )
      end

      @test_session.scoping.authorised_http_headers = [ 'HTTP_X_RESOURCE_UUID' ]
      do_patch( :a, { 'foo' => true }, { 'HTTP_X_RESOURCE_UUID' => Hoodoo::UUID.generate() } )
    end

    it 'rejects session-authorised but invalid IDs' do
      def expectations( hash )
        expect( last_response.status ).to eq( 422 )
        expect( JSON.parse( last_response.body )[ 'errors' ][ 0 ][ 'reference' ] ).to eq( 'X-Resource-UUID' )
      end

      @test_session.scoping.authorised_http_headers = [ 'HTTP_X_RESOURCE_UUID' ]
      do_post( :a, { 'foo' => 'hello', 'bar' => 42 }, { 'HTTP_X_RESOURCE_UUID' => 'not a valid UUID' } )
    end

    it 'rejects requests with no authorised headers' do
      def expectations( hash )
        expect( last_response.status ).to eq( 403 )

        # Check for a *generic* platform.forbidden message. It isn't even very
        # accurate but the whole point is that we don't reveal the exact nature
        # of the authorisation failure (use of a secure header without session
        # permissions) because that would be an information disclosure bug.
        #
        expect( JSON.parse( last_response.body )[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
      end

      do_post( :a, { 'foo' => 'hello', 'bar' => 42 }, { 'HTTP_X_RESOURCE_UUID' => Hoodoo::UUID.generate } )
    end

    it 'rejects requests with malformed (nil) authorised header collection' do
      def expectations( hash )
        expect( last_response.status ).to eq( 403 )
        expect( JSON.parse( last_response.body )[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
      end

      @test_session.scoping.authorised_http_headers = nil
      do_post( :a, { 'foo' => 'hello', 'bar' => 42 }, { 'HTTP_X_RESOURCE_UUID' => Hoodoo::UUID.generate } )
    end

    it 'rejects requests with an explicitly empty authorised header collection' do
      def expectations( hash )
        expect( last_response.status ).to eq( 403 )
        expect( JSON.parse( last_response.body )[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
      end

      @test_session.scoping.authorised_http_headers = []
      do_post( :a, { 'foo' => 'hello', 'bar' => 42 }, { 'HTTP_X_RESOURCE_UUID' => Hoodoo::UUID.generate } )
    end

    it 'rejects requests with mismatched authorised headers' do
      def expectations( hash )
        expect( last_response.status ).to eq( 403 )
        expect( JSON.parse( last_response.body )[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
      end

      @test_session.scoping.authorised_http_headers = [ 'HTTP_NOT_X_RESOURCE_UUID' ]
      do_post( :a, { 'foo' => 'hello', 'bar' => 42 }, { 'HTTP_X_RESOURCE_UUID' => Hoodoo::UUID.generate } )
    end
  end

  # There's coverage for nil payloads elsewhere as well, but once more,
  # add extra coverage here.

  context 'edge cases:' do
    def expectations( hash )
      expect( last_response.status ).to eq( 422 )
      expect( JSON.parse( last_response.body )[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'generic.malformed' )
    end

    it 'no body data' do
      do_post( :a, nil )
      do_patch( :a, nil )
      do_post( :b, nil )
      do_patch( :b, nil )
    end
  end
end
