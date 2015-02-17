require 'spec_helper'

describe Hoodoo::Services::Session do

  before :each do
    Hoodoo::Services::Session::MockDalliClient.reset()
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

    expect( s1.save_to_memcached ).to eq( true )

    store = Hoodoo::Services::Session::MockDalliClient.store()
    expect( store[ '1234' ] ).to_not be_nil
    expect( store[ '0987' ] ).to eq( { :expires_at => nil, :value => { 'version' => 2 } } )

    # Check that session gains an expiry time when saved.
    #
    expect( s1.expires_at ).to be_a( Time )

    # Ensure "created_at" is significantly different in the next session.
    # This is important to reliably detect session load failures in testing
    # given "#iso8601()" time resolution limits and so-on.
    #
    sleep( 0.2 )

    s2 = described_class.new
    expect( s2.load_from_memcached!( s1.session_id ) ).to eq( true )

    expect( s2.created_at ).to eq( Time.parse( s1.created_at.iso8601 ) )
    expect( s2.expires_at ).to eq( Time.parse( s1.expires_at.iso8601 ) )
    expect( s2.session_id ).to eq( s1.session_id )
    expect( s2.memcached_host ).to be_nil
    expect( s2.caller_id ).to eq( s1.caller_id )
    expect( s2.caller_version ).to eq( s1.caller_version )
  end

  it 'refuses to save if a newer caller version is present' do
    expect( described_class ).to receive( :connect_to_memcached ).twice.and_return( Hoodoo::Services::Session::MockDalliClient.new )

    # Save a session with a high caller version

    s1 = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 4
    )

    expect( s1.save_to_memcached ).to eq( true )

    # Save another with, initially, a lower caller version. The idea here
    # is that session creation is underway when a caller gets updated.

    s2 = described_class.new(
      :session_id => '2345',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 3
    )

    expect( s2.save_to_memcached ).to eq( false )
  end

  it 'invalidates a session if the client ID advances during its lifetime' do
    expect( described_class ).to receive( :connect_to_memcached ).exactly( 4 ).times.and_return( Hoodoo::Services::Session::MockDalliClient.new )
    loader = described_class.new

    # Save a session with a low caller version.

    s1 = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    expect( s1.save_to_memcached ).to eq( true )

    # Save another with a higher caller version.

    s2 = described_class.new(
      :session_id => '2345',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 2
    )

    expect( s2.save_to_memcached ).to eq( true )

    # Should not be able to load the first one anymore.

    expect( loader.load_from_memcached!( '1234' ) ).to eq( false )
    expect( loader.load_from_memcached!( '2345' ) ).to eq( true  )
  end

  it 'refuses to load if the caller version is outdated' do
    expect( described_class ).to receive( :connect_to_memcached ).exactly( 5 ).times.and_return( Hoodoo::Services::Session::MockDalliClient.new )
    loader = described_class.new

    # Save a session with a low caller version

    s1 = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    expect( s1.save_to_memcached ).to eq( true )

    # Should be able to load it back.

    expect( loader.load_from_memcached!( '1234' ) ).to eq( true )

    # Save another with a higher caller version.

    s2 = described_class.new(
      :session_id => '2345',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 2
    )

    expect( s2.save_to_memcached ).to eq( true )

    # Try to load the first one again; should fail.

    expect( loader.load_from_memcached!( '1234' ) ).to eq( false )

    # The newer one should load OK.

    expect( loader.load_from_memcached!( '2345' ) ).to eq( true )
  end

  it 'refuses to load if expired' do
    expect( described_class ).to receive( :connect_to_memcached ).twice.and_return( Hoodoo::Services::Session::MockDalliClient.new )
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

    expect( s.save_to_memcached ).to eq( true )
    expect( loader.load_from_memcached!( '1234' ) ).to eq( false )
  end

  it 'can explicitly update a caller' do
    s = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    expect( described_class ).to receive( :connect_to_memcached ).once.and_return( Hoodoo::Services::Session::MockDalliClient.new )

    expect( s.update_caller_version_in_memcached( '9944', 23                                                 ) ).to eq( true )
    expect( s.update_caller_version_in_memcached( 'abcd', 2,  Hoodoo::Services::Session::MockDalliClient.new ) ).to eq( true )

    store = Hoodoo::Services::Session::MockDalliClient.store()
    expect( store[ '9944' ] ).to eq( { :expires_at => nil, :value => { 'version' => 23 } } )
    expect( store[ 'abcd' ] ).to eq( { :expires_at => nil, :value => { 'version' => 2  } } )
  end

  it 'handles invalid session IDs when loading' do
    expect( described_class ).to receive( :connect_to_memcached ).once.and_return( Hoodoo::Services::Session::MockDalliClient.new )
    loader = described_class.new
    expect( loader.load_from_memcached!( '1234' ) ).to be_nil
  end

  it 'complains if there is no caller ID' do
    s = described_class.new
    expect {
      s.save_to_memcached()
    }.to raise_error RuntimeError
  end

  it 'logs Memcached exceptions when loading' do
    fdc = Hoodoo::Services::Session::MockDalliClient.new
    expect( described_class ).to receive( :connect_to_memcached ).once.and_return( fdc )
    loader = described_class.new

    expect( fdc ).to receive( :get ).once do
      raise 'Mock Memcached connection failure'
    end

    expect( Hoodoo::Services::Middleware.logger ).to receive( :warn ).once.and_call_original
    expect( loader.load_from_memcached!( '1234' ) ).to be_nil
  end

  it 'logs Memcached exceptions when saving' do
    fdc = Hoodoo::Services::Session::MockDalliClient.new
    expect( described_class ).to receive( :connect_to_memcached ).once.and_return( fdc )

    s = described_class.new(
      :caller_id => '0987',
      :caller_version => 1
    )

    expect( fdc ).to receive( :set ).once do
      raise 'Mock Memcached connection failure'
    end

    expect( Hoodoo::Services::Middleware.logger ).to receive( :warn ).once.and_call_original
    expect( s.save_to_memcached() ).to be_nil
  end

  it 'can be deleted' do
    fdc = Hoodoo::Services::Session::MockDalliClient.new
    allow( described_class ).to receive( :connect_to_memcached ).and_return( fdc )

    s = described_class.new(
      :session_id => '1234',
      :memcached_host => 'abcd',
      :caller_id => '0987',
      :caller_version => 1
    )

    s.save_to_memcached

    expect{ s.delete_from_memcached }.to change{ s.load_from_memcached!( s.session_id ) }.from( true ).to( nil )
  end

  # We really can't do this without insisting on testers having a
  # Memcached instance; instead, assume Dalli works (!) and mock it.
  #
  context 'real Memcached connection code test coverage' do
    before :example do
      Hoodoo::Services::Session::MockDalliClient.bypass( true )
    end

    after :example do
      Hoodoo::Services::Session::MockDalliClient.bypass( false )
    end

    it 'complains about a missing host' do
      expect {
        described_class.connect_to_memcached( nil )
      }.to raise_error RuntimeError

      expect {
        described_class.connect_to_memcached( '' )
      }.to raise_error RuntimeError
    end

    it 'tries to connect' do
      expect_any_instance_of( Dalli::Client ).to receive( :stats ).and_return( {} )
      expect( described_class.connect_to_memcached( '256.2.3.4:0' ) ).to be_a( Dalli::Client )
    end

    it 'handles connection failures' do
      expect_any_instance_of( Dalli::Client ).to receive( :stats ).and_return( nil )
      expect {
        described_class.connect_to_memcached( '256.2.3.4:0' )
      }.to raise_error RuntimeError
    end

    it 'handles connection exceptions' do
      expect_any_instance_of( Dalli::Client ).to receive( :initialize ) do
        raise 'Mock Memcached connection failure'
      end

      expect {
        described_class.connect_to_memcached( '256.2.3.4:0' )
      }.to raise_error RuntimeError
    end
  end
end
