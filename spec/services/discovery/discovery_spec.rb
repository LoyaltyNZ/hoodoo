require 'spec_helper'

describe Hoodoo::Services::Discovery do
  context 'alone' do
    it 'supports announcement directly' do
      d = described_class.new
      expect( d.announce( 'Foo', 3 ) ).to eq( true )
    end

    # Note intentional mixed Symbol / String usage.

    it 'records local announcements' do
      d = described_class.new
      expect( d.announce( 'Foo', 3 ) ).to eq( true )
      expect( d.is_local?( :Foo, 3 ) ).to eq( true )
      expect( d.is_local?( 'Foo', 2 ) ).to eq( false )
      expect( d.is_local?( 'Bar', 3 ) ).to eq( false )
      expect( d.is_local?( 'Bar', 2 ) ).to eq( false )
    end

    it 'complains about missing subclass implementations' do
      d = described_class.new
      expect {
        d.discover( 'Foo', 3 )
      }.to raise_exception( RuntimeError, "Hoodoo::Services::Discovery::Base subclass does not implement remote discovery required for resource 'Foo' / version '3'" )
    end
  end

  context 'when subclassed' do
    class RSpecTestDiscoverer < described_class
      def announce_remote( resource, version, options )
        'announce'
      end
      def discover_remote( resource, version, options )
        'discover'
      end
    end

    it 'calls with configuration options' do
      opts = { :foo => :bar, :bar => :baz }
      expect_any_instance_of( RSpecTestDiscoverer ).to receive( :configure_with ).with( opts ).and_call_original
      RSpecTestDiscoverer.new( opts )
    end

    it 'passes announcements on' do
      opts = { :foo => :bar, :bar => :baz }
      d = RSpecTestDiscoverer.new
      expect( d ).to receive( :announce_remote ).with( 'Foo', 3, opts ).and_call_original
      expect( d.announce( :Foo, 3, opts ) ).to eq( 'announce' )
      expect( d ).to receive( :announce_remote ).with( 'Foo', 3, {} ).and_call_original
      expect( d.announce( 'Foo', 3 ) ).to eq( 'announce' )
      expect( d ).to receive( :announce_remote ).with( 'Foo', 1, {} ).and_call_original
      expect( d.announce( :Foo ) ).to eq( 'announce' )
    end

    it 'does not pass local discovery on' do
      d = RSpecTestDiscoverer.new
      d.announce( 'Baz', 4 )

      expect( d ).to_not receive( :discover_remote )
      expect( d.discover( 'Baz', 4 ) ).to eq( 'announce' )
    end

    it 'passes remote discovery on' do
      opts = { :foo => :bar, :bar => :baz }
      d = RSpecTestDiscoverer.new
      d.announce( :Bar, 2 )
      d.instance_variable_set( '@known_local_resources', {} ) # Hack for test!

      expect( d ).to receive( :discover_remote ).with( 'Bar', 2, opts ).and_call_original
      expect( d.discover( 'Bar', 2, opts ) ).to eq( 'discover' )
    end
  end
end
