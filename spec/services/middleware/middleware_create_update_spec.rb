# Specific tests for behaviour around the middleware's enforcement of
# the to_create/to_update DSL through service interfaces and validation
# of inbound payloads.

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

    to_create do
      text :foo
      integer :bar, :required => true
      integer :defaulted, :default => 42
    end

    to_update do
      boolean :foo, :required => true
      enum :bar, :from => [ :foo, :bar, :baz ]
      integer :defaulted, :default => 24
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

# Put them both in the same service application for simplicity.

class RSpecToUpdateToCreateTestService < Hoodoo::Services::Service
  comprised_of RSpecToUpdateToCreateTestAInterface,
               RSpecToUpdateToCreateTestBInterface
end

# Finally, the tests.

describe Hoodoo::Services::Middleware do
  def app
    Rack::Builder.new do
      use Hoodoo::Services::Middleware
      run RSpecToUpdateToCreateTestService.new
    end
  end

  def do_post( variant, hash ) # Variant is :a or :b
    post "/v1/r_spec_to_update_to_create_test_#{ variant }/",
         hash.nil? ? '' : JSON.generate( hash ),
         { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

    expectations( hash )
  end

  def do_patch( variant, hash ) # Variant is :a or :b
    patch "/v1/r_spec_to_update_to_create_test_#{ variant }/any",
          hash.nil? ? '' : JSON.generate( hash ),
          { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

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
      do_patch( :b, 'actions' => { 'list' => 'allow' }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
    end

    it 'with required fields only' do
      do_post( :a, 'bar' => 42 )
      do_patch( :a, 'foo' => true )
      do_post( :b, 'code' => 'hello', 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
    end

    # Explicit nils should be preserved through rendering and
    # accepted through the checking engine (for non-required data).
    #
    it 'with explicit nils' do
      do_post( :a, 'foo' => nil, 'bar' => 42 )
      do_patch( :a, 'foo' => true, 'bar' => nil )
      do_post( :b, 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_patch( :b, 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
    end
  end

  context 'rejects unknown data' do
    def expectations( hash )
      expect( last_response.status ).to eq( 422 )
      expect( JSON.parse( last_response.body )[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Body data contains unrecognised or prohibited fields' )
    end

    it 'with many fields' do
      do_post( :a, 'foo' => 'hello', 'bar' => 42, 'random' => true )
      do_patch( :a, 'foo' => true, 'bar' => 'foo', 'random' => true )
      do_post( :b, 'code' => 'hello', 'random' => true, 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'actions' => { 'list' => 'allow' }, 'random' => true, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
    end

    it 'with required fields only' do
      do_post( :a, 'bar' => 42, 'random' => true )
      do_patch( :a, 'foo' => true, 'random' => true )
      do_post( :b, 'code' => 'hello', 'random' => true, 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'random' => true, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
    end

    it 'with explicit nils' do
      do_post( :a, 'foo' => nil, 'bar' => 42, 'random' => true )
      do_patch( :a, 'foo' => true, 'bar' => nil, 'random' => true )
      do_post( :b, 'code' => 'hello', 'random' => true, 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'actions' => nil, 'random' => true, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_patch( :b, 'actions' => { 'list' => nil }, 'random' => true, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
    end
  end

  context 'rejects known but prohibited fields' do
    def expectations( hash )
      expect( last_response.status ).to eq( 422 )
      expect( JSON.parse( last_response.body )[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Body data contains unrecognised or prohibited fields' )
    end

    it 'with many fields' do
      do_post( :b,  'id' => Hoodoo::UUID.generate, 'code' => 'hello', 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'id' => Hoodoo::UUID.generate, 'actions' => { 'list' => 'allow' }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_post( :b,  'kind' => 'Foo', 'code' => 'hello', 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'kind' => 'Foo', 'actions' => { 'list' => 'allow' }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_post( :b,  'created_at' => Time.now.iso8601, 'code' => 'hello', 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'created_at' => Time.now.iso8601, 'actions' => { 'list' => 'allow' }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_post( :b,  'language' => 'fr', 'code' => 'hello', 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'language' => 'fr', 'actions' => { 'list' => 'allow' }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
    end

    it 'with required fields only' do
      do_post( :b,  'id' => Hoodoo::UUID.generate, 'code' => 'hello', 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'id' => Hoodoo::UUID.generate, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_post( :b,  'kind' => 'Foo', 'code' => 'hello', 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'kind' => 'Foo', 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_post( :b,  'created_at' => Time.now.iso8601, 'code' => 'hello', 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'created_at' => Time.now.iso8601, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_post( :b,  'language' => 'fr', 'code' => 'hello', 'message' => 'world', 'errors' => [] )
      do_patch( :b, 'language' => 'fr', 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
    end

    it 'with explicit nils' do
      do_post( :b,  'id' => Hoodoo::UUID.generate, 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'id' => Hoodoo::UUID.generate, 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_patch( :b, 'id' => Hoodoo::UUID.generate, 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_post( :b,  'kind' => 'Foo', 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'kind' => 'Foo', 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_patch( :b, 'kind' => 'Foo', 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_post( :b,  'created_at' => Time.now.iso8601, 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'created_at' => Time.now.iso8601, 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_patch( :b, 'created_at' => Time.now.iso8601, 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_post( :b,  'language' => 'fr', 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'language' => 'fr', 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
      do_patch( :b, 'language' => 'fr', 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
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
      do_patch( :b, 'actions' => 'not an object', 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
    end

    it 'with required fields only' do
      do_post( :a, 'bar' => 'still not an integer' )
      do_patch( :a, 'foo' => 'still not a boolean' )
      do_post( :b, 'code' => 'hello', 'message' => 'world', 'errors' => 'not an array' )
      do_patch( :b, 'caller_id' => 'not a uuid', 'expires_at' => Time.now.iso8601, 'identifier' => 'baz' )
    end

    it 'with explicit nils' do
      do_post( :a, 'foo' => nil, 'bar' => 'still not an integer' )
      do_patch( :a, 'foo' => 'still not a boolean', 'bar' => nil )
      do_post( :b, 'code' => 'hello', 'message' => 'world', 'reference' => nil, 'errors' => 'still not an array' )
      do_patch( :b, 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => 'not a time', 'identifier' => 'baz' )
      do_patch( :b, 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => 'not a time', 'identifier' => 'baz' )
    end
  end

  # There's coverage for ":required => true" elsewhere too, but again,
  # may as well add extra coverage for to-create/to-update here.

  context 'requires required fields' do
    def expectations( hash )
      expect( last_response.status ).to eq( 422 )
      expect( JSON.parse( last_response.body )[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'generic.required_field_missing' )
    end

    it 'with many fields' do
      do_post( :a, 'foo' => 'hello' )
      do_patch( :a, 'bar' => 'foo' )
      do_post( :b, 'message' => 'world', 'reference' => 'baz', 'errors' => [] )
      do_patch( :b, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => nil )
    end

    it 'with empty data' do
      do_post( :a, {} )
      do_patch( :a, {} )
      do_post( :b, {} )
      do_patch( :b, {} )
    end

    it 'with explicit nils' do
      do_post( :a, 'bar' => nil )
      do_patch( :a, 'foo' => nil )
      do_post( :b, 'code' => nil, 'message' => 'world', 'reference' => nil, 'errors' => [] )
      do_patch( :b, 'actions' => nil, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => nil )
      do_patch( :b, 'actions' => { 'list' => nil }, 'caller_id' => Hoodoo::UUID.generate, 'expires_at' => Time.now.iso8601, 'identifier' => nil )
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
