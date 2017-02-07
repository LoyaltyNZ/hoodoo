require 'spec_helper'
require 'hoodoo/transient_store/mocks/dalli_client'

describe Hoodoo::Services::Session do

  before :each do
    spec_helper_use_mock_memcached()
  end

  it 'includes a legacy alias to the TransientStore mock back-end' do
    expect( Hoodoo::Services::Session::MockDalliClient == Hoodoo::TransientStore::Mocks::DalliClient ).to eql( true )
    expect {
      Hoodoo::TransientStore::Mocks::DalliClient.reset()
    }.to_not raise_error
  end

  it 'defines aliases for legacy methods' do
    s = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 2
    )

    expect( s ).to respond_to( :save_to_memcached )
    expect( s ).to respond_to( :load_from_memcached! )
    expect( s ).to respond_to( :update_caller_version_in_memcached )
    expect( s ).to respond_to( :delete_from_memcached )
  end

  it 'initialises with default options' do
    s = described_class.new()
    expect( s.created_at ).to be_a( Time )
    expect( Hoodoo::UUID.valid?( s.session_id ) ).to eq( true )
    expect( s.memcached_host ).to be_nil
    expect( s.caller_id ).to be_nil
    expect( s.caller_version ).to eq( 0 )
  end

  it 'initialises with given options' do
    s = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 2
    )
    expect( s.created_at ).to be_a( Time )
    expect( s.session_id ).to eq( '1234' )
    expect( s.memcached_host ).to eq( 'abcd' )
    expect( s.caller_id ).to eq( '0987' )
    expect( s.caller_version ).to eq( 2 )
  end

  it 'reports not expired when it has no expiry' do
    s = described_class.new
    expect( s.expired? ).to eq( false )
  end

  it 'knows if expired' do
    s = described_class.new
    s.instance_variable_set( '@expires_at', Time.now - 1 )
    expect( s.expired? ).to eq( true )
  end

  it 'converts to a Hash' do
    s = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 2
    )
    p = Hoodoo::Services::Permissions.new

    s.permissions = p
    s.identity = { 'foo' => 'foo', 'bar' => 'bar' }
    s.scoping = { 'baz' => [ 'foo', 'bar', 'baz' ] }

    h = s.to_h

    expect( h ).to eq( {
      'session_id'     => '1234',
      'caller_id'      => '0987',
      'caller_version' => 2,

      'created_at'     => s.created_at.iso8601,

      'identity'       => { 'foo' => 'foo', 'bar' => 'bar' },
      'scoping'        => { 'baz' => [ 'foo', 'bar', 'baz' ] },
      'permissions'    => p.to_h()
    } )
  end

  it 'reads from a Hash' do
    s = described_class.new
    p = Hoodoo::Services::Permissions.new
    c = Time.now.utc
    e = Time.now.utc + 10
    h = {
      'session_id'     => '1234',
      'caller_id'      => '0987',
      'caller_version' => 2,

      'created_at'     => c.iso8601,
      'expires_at'     => e.iso8601,

      'identity'       => { 'foo' => 'foo', 'bar' => 'bar' },
      'scoping'        => { 'baz' => [ 'foo', 'bar', 'baz' ] },
      'permissions'    => p.to_h()
    }

    s.from_h!( h )

    expect( s.session_id ).to eq( '1234' )
    expect( s.caller_id ).to eq( '0987' )
    expect( s.caller_version ).to eq( 2 )
    expect( s.created_at ).to eq( Time.parse( c.iso8601 ) )
    expect( s.expires_at ).to eq( Time.parse( e.iso8601 ) )
    expect( s.identity.foo ).to eq( 'foo' )
    expect( s.identity.bar ).to eq( 'bar' )
    expect( s.scoping.baz ).to eq( [ 'foo', 'bar', 'baz' ] )
    expect( s.permissions.to_h ).to eq( p.to_h )
  end

  it 'saves/loads to/from Memcached' do
    s1 = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 2
    )

    expect( s1.save_to_store ).to eq( :ok )

    store = Hoodoo::TransientStore::Mocks::DalliClient.store()
    expect( store[ '1234' ] ).to_not be_nil
    expect( store[ '0987' ] ).to include( { :value => { 'version' => 2 } } )
    expect( store[ '0987' ] ).to have_key( :expires_at )
    expect( store[ '0987' ][ :expires_at ] ).to be_a( Time )

    # Check that session gains an expiry time when saved.
    #
    expect( s1.expires_at ).to be_a( Time )

    # Ensure "created_at" is significantly different in the next session.
    # This is important to reliably detect session load failures in testing
    # given "#iso8601()" time resolution limits and so-on.
    #
    sleep( 0.2 )

    s2 = described_class.new
    expect( s2.load_from_store!( s1.session_id ) ).to eq( :ok )

    expect( s2.created_at ).to eq( Time.parse( s1.created_at.iso8601 ) )
    expect( s2.expires_at ).to eq( Time.parse( s1.expires_at.iso8601 ) )
    expect( s2.session_id ).to eq( s1.session_id )
    expect( s2.memcached_host ).to be_nil
    expect( s2.caller_id ).to eq( s1.caller_id )
    expect( s2.caller_version ).to eq( s1.caller_version )
  end

  it 'refuses to save if a newer caller version is present' do

    # Save a session with a high caller version

    s1 = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 4
    )

    expect( s1.save_to_store ).to eq( :ok )

    # Save another with, initially, a lower caller version. The idea here
    # is that session creation is underway when a caller gets updated.

    s2 = described_class.new(
      :session_id => '2345',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 3
    )

    expect( s2.save_to_store ).to eq( :outdated )
  end

  it 'invalidates a session if the client ID advances during its lifetime' do
    loader = described_class.new

    # Save a session with a low caller version.

    s1 = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    expect( s1.save_to_store ).to eq( :ok )

    # Save another with a higher caller version.

    s2 = described_class.new(
      :session_id => '2345',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 2
    )

    expect( s2.save_to_store ).to eq( :ok )

    # Should not be able to load the first one anymore.

    expect( loader.load_from_store!( '1234' ) ).to eq( :outdated )
    expect( loader.load_from_store!( '2345' ) ).to eq( :ok       )
  end

  it 'refuses to load if the caller version is outdated' do
    loader = described_class.new

    # Save a session with a low caller version

    s1 = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    expect( s1.save_to_store ).to eq( :ok )

    # Should be able to load it back.

    expect( loader.load_from_store!( '1234' ) ).to eq( :ok )

    # Save another with a higher caller version.

    s2 = described_class.new(
      :session_id => '2345',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 2
    )

    expect( s2.save_to_store ).to eq( :ok )

    # Try to load the first one again; should fail.

    expect( loader.load_from_store!( '1234' ) ).to eq( :outdated )

    # The newer one should load OK.

    expect( loader.load_from_store!( '2345' ) ).to eq( :ok )
  end

  it 'refuses to load if expired' do
    loader = described_class.new

    # Save a session with a high caller version

    s = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    expect( s ).to receive( :to_h ).and_wrap_original do | obj, args |
      h = obj.call( *args )
      h[ 'expires_at' ] = ( Time.now - 1 ).utc.iso8601
      h
    end

    expect( s.save_to_store ).to eq( :ok )
    expect( loader.load_from_store!( '1234' ) ).to eq( :outdated )
  end

  context 'can explicitly update a caller' do
    before :each do
      @session = described_class.new(
        :session_id => '1234',
        :memcached_host => 'abcd',
        :caller_id => '0987',
        :caller_version => 1
      )
    end

    after :each do
      store = Hoodoo::TransientStore::Mocks::DalliClient.store()
      expect( store[ '0987' ] ).to include( { :value => { 'version' => 23 } } )
      expect( store[ 'efgh' ] ).to include( { :value => { 'version' => 3  } } )
    end

    it 'with modern interface and no caller-supplied client' do
      expect( @session.update_caller_version_in_store( '0987', 23 ) ).to eq( :ok )
      expect( @session.update_caller_version_in_store( 'efgh', 3  ) ).to eq( :ok )
    end

    it 'with modern interface and caller-supplied Hoodoo::TransientStore instance' do
      local_store = Hoodoo::TransientStore.new(
        storage_engine:   :memcached,
        storage_host_uri: 'abcd'
      )

      expect( @session.update_caller_version_in_store( '0987', 23, local_store ) ).to eq( :ok )
      expect( @session.update_caller_version_in_store( 'efgh', 3,  local_store ) ).to eq( :ok )
    end

    it 'with deprecated interface and no caller-supplied client' do
      expect( @session.update_caller_version_in_memcached( '0987', 23 ) ).to eq( :ok )
      expect( @session.update_caller_version_in_memcached( 'efgh', 3  ) ).to eq( :ok )
    end

    it 'with deprecated interface and caller-supplied Dalli::Client instance' do
      local_store = Hoodoo::TransientStore::Mocks::DalliClient.new

      expect( @session.update_caller_version_in_memcached( '0987', 23, local_store ) ).to eq( :ok )
      expect( @session.update_caller_version_in_memcached( 'efgh', 3,  local_store ) ).to eq( :ok )
    end
  end

  it 'handles invalid session IDs when loading' do
    loader = described_class.new
    expect( loader.load_from_store!( '1234' ) ).to eq( :not_found )
  end

  it 'complains if there is no caller ID' do
    s = described_class.new
    expect {
      s.save_to_store()
    }.to raise_error RuntimeError
  end

  it 'logs Memcached exceptions when loading' do
    loader = described_class.new

    expect_any_instance_of( Hoodoo::TransientStore::Mocks::DalliClient ).to receive( :get ).once do
      raise 'Mock Memcached connection failure'
    end

    expect( Hoodoo::Services::Middleware.logger ).to(
      receive( :warn ).once.with(
        'Hoodoo::Services::Session\\#load_from_store!: Session loading failed - connection fault or session corrupt',
        'Mock Memcached connection failure'
      ).and_call_original
    )

    expect( loader.load_from_store!( '1234' ) ).to eq( :fail )
  end

  it 'logs Memcached exceptions when updating caller version during session saving' do
    s = described_class.new(
      :caller_id => '0987',
      :caller_version => 1
    )

    # The first 'set' call is an attempt to update the caller version before
    # the updated session is saved.

    expect_any_instance_of( Hoodoo::TransientStore::Mocks::DalliClient ).to receive( :set ).once do
      raise 'Mock Memcached connection failure'
    end

    expect( Hoodoo::Services::Middleware.logger ).to(
      receive( :warn ).once.with(
        'Hoodoo::Services::Session\\#update_caller_version_in_store: Client version update - connection fault or corrupt record',
        'Mock Memcached connection failure'
      ).and_call_original
    )

    expect( s.save_to_store() ).to eq( :fail )
  end

  it 'logs Memcached exceptions when saving session' do
    s = described_class.new(
      :caller_id => '0987',
      :caller_version => 1
    )

    expect_any_instance_of( Hoodoo::TransientStore::Mocks::DalliClient ).to receive( :set ).once.and_call_original
    expect_any_instance_of( Hoodoo::TransientStore::Mocks::DalliClient ).to receive( :set ).once do
      raise 'Mock Memcached connection failure'
    end

    expect( Hoodoo::Services::Middleware.logger ).to(
      receive( :warn ).once.with(
        'Hoodoo::Services::Session\\#save_to_store: Session saving failed - connection fault or session corrupt',
        'Mock Memcached connection failure'
      ).and_call_original
    )

    expect( s.save_to_store() ).to eq( :fail )
  end

  it 'can be deleted' do
    s = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    s.save_to_store

    expect{ s.delete_from_store }.to change{ s.load_from_store!( s.session_id ) }.from( :ok ).to( :not_found )
  end

  it 'handles attempts to delete not-found things' do
    s = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    expect( s.delete_from_store ).to eq( :ok )
  end

  it 'handles unknown Hoodoo::TransientStore engine failures' do
    s = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    s.save_to_store
    allow_any_instance_of( Hoodoo::TransientStore ).to(
      receive( :delete ).
      and_return( false )
    )

    expect( Hoodoo::Services::Middleware.logger ).to receive( :warn )
    expect( s.delete_from_store ).to eq( :fail )
  end

  it 'handles unknown Hoodoo::TransientStore engine returned exceptions' do
    s = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    s.save_to_store
    allow_any_instance_of( Hoodoo::TransientStore ).to(
      receive( :delete ).
      and_return( RuntimeError.new( 'Intentional exception' ) )
    )

    expect( Hoodoo::Services::Middleware.logger ).to receive( :warn )
    expect( s.delete_from_store ).to eq( :fail )
  end

  it 'logs and reports internal deletion exceptions' do
    s = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    s.save_to_store

    allow_any_instance_of( described_class ).to(
      receive( :get_store ).
      and_raise( 'Intentional exception' )
    )

    expect( Hoodoo::Services::Middleware.logger ).to receive( :warn )
    expect( s.delete_from_store ).to eq( :fail )
  end

  context 'legacy Memcached connection code test coverage' do
    before :example do

      # Clear the connection cache for each test
      #
      Hoodoo::Services::Session.class_variable_set( '@@stores', nil ) # Hack for test!

      @instance = described_class.new(
        :session_id => '1234',
        :memcached_host => 'abcd',
        :caller_id => '0987',
        :caller_version => 1
      )
    end

    it 'tries to connect' do
      expect_any_instance_of( Hoodoo::TransientStore::Mocks::DalliClient ).to receive( :stats ).and_return( {} )
      expect( @instance.send( :get_store ) ).to be_a( Hoodoo::TransientStore )
    end

    it 'handles connection failures' do
      expect_any_instance_of( Hoodoo::TransientStore::Mocks::DalliClient ).to receive( :stats ).and_return( nil )
      expect {
        @instance.send( :get_store )
      }.to raise_error RuntimeError
    end

    it 'handles connection exceptions' do
      expect_any_instance_of( Hoodoo::TransientStore ).to receive( :initialize ) do
        raise 'Mock TransientStore constructor failure'
      end

      expect {
        @instance.send( :get_store )
      }.to raise_error RuntimeError
    end

    it 'only initialises once for one given host' do
      expect( Hoodoo::TransientStore::Memcached ).to receive( :new ).once.and_call_original()

      @instance.memcached_host = 'one'
      1.upto( 3 ) do
        @instance.send( :get_store )
      end

      expect( Hoodoo::TransientStore::Memcached ).to receive( :new ).once.and_call_original()

      @instance.memcached_host = 'two'
      1.upto( 3 ) do
        @instance.send( :get_store )
      end
    end
  end
end
