require 'spec_helper'

describe Hoodoo::Services::Session do

  # Fake known uses of Dalli::Client with test implementations.

  class FakeDalliClient
    @@store = {}

    def initialize( ignored1 = nil, ignored2 = nil )
    end

    def self.store # For test analysis
      @@store
    end

    def get( key )
      data = @@store[ key ]
      return nil if data.nil?

      expires_at = data[ :expires_at ]
      return nil unless expires_at.nil? || Time.now < expires_at

      return data[ :value ]
    end

    def set( key, value, ttl = nil )
      data = {
        :expires_at => ttl.nil? ? nil : Time.now.utc + ttl,
        :value      => value
      }

      @@store[ key ] = data
    end

    def stats
      true
    end
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

    s.from_h( h )

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

    expect( s1.class ).to receive( :connect_to_memcached ).twice.and_return( FakeDalliClient.new )

    expect( s1.save_to_memcached ).to eq( s1.expires_at )

    store = FakeDalliClient.store()
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

  # Other tests:
  #
  # - saving to memcache when a newer client record is already present
  # - loading from memcache and finding out you've expired
  # - loading from memcache and not-found
  # - loading from memcache when the client version has changed in the meantime

end
