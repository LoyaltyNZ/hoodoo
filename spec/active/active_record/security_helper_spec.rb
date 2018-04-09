require 'spec_helper'

describe Hoodoo::ActiveRecord::Finder::SecurityHelper do

  class TestAllMatchersObject
    def     eql?( thing ); true; end
    def include?( thing ); true; end
  end

  context '::eqls_wildcard' do
    before :each do
      @proc = Hoodoo::ActiveRecord::Finder::SecurityHelper.eqls_wildcard( '!' )
    end

    it 'matches when it should' do
      expect( @proc.call( '!' ) ).to eql( true )
      expect( @proc.call( Eql.new ) ).to eql( true )
    end

    it 'misses when it should' do
      expect( @proc.call( '*' ) ).to eql( false )
      expect( @proc.call( ' !' ) ).to eql( false )
      expect( @proc.call( '! ' ) ).to eql( false )
      expect( @proc.call( "!\n" ) ).to eql( false )
      expect( @proc.call( 42 ) ).to eql( false )
      expect( @proc.call( { :hello => :world } ) ).to eql( false )
      expect( @proc.call( [ 1, 2, 3, 4 ] ) ).to eql( false )
    end

    it 'rescues' do
      uneql = Object.new
      uneql.instance_eval( 'undef :eql?' )
      expect( @proc.call( uneql ) ).to eql( false )
    end
  end

  context '::includes_wildcard' do
    before :each do
      @proc = Hoodoo::ActiveRecord::Finder::SecurityHelper.includes_wildcard( '!' )
    end

    it 'matches when it should' do
    end

    it 'misses when it should' do
    end

    it 'rescues' do
    end
  end

  context '::matches_wildcard' do
  end

  context '::matches_wildcard_enumerable' do
  end
end
