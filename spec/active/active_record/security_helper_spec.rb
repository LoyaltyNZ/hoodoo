require 'spec_helper'

describe Hoodoo::ActiveRecord::Finder::SecurityHelper do

  class TestAllMatchersObject
    include Enumerable

    def     eql?( thing ); true; end
    def include?( thing ); true; end
    def   match?( thing ); true; end
  end

  class TestRescueAllMatchersObject
    include Enumerable

    def     eql?( thing ); raise "boo!"; end
    def include?( thing ); raise "boo!"; end
    def   match?( thing ); raise "boo!"; end
  end

  context '::eqls_wildcard' do
    before :each do
      @proc = Hoodoo::ActiveRecord::Finder::SecurityHelper.eqls_wildcard( '!' )
    end

    it 'matches when it should' do
      expect( @proc.call( '!' ) ).to eql( true )
      expect( @proc.call( TestAllMatchersObject.new ) ).to eql( true )
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
      expect( @proc.call( TestRescueAllMatchersObject.new ) ).to eql( false )
    end
  end

  context '::includes_wildcard' do
    before :each do
      @proc = Hoodoo::ActiveRecord::Finder::SecurityHelper.includes_wildcard( '!' )
    end

    it 'matches when it should' do
      expect( @proc.call( [ '!' ] ) ).to eql( true )
      expect( @proc.call( [ '!', 1, 2, 3, 4 ] ) ).to eql( true )
      expect( @proc.call( [ 1, 2, '!', 3, 4 ] ) ).to eql( true )
      expect( @proc.call( [ 1, 2, 3, 4, '!' ] ) ).to eql( true )
      expect( @proc.call( TestAllMatchersObject.new ) ).to eql( true )
    end

    it 'misses when it should' do
      expect( @proc.call( '!' ) ).to eql( false )
      expect( @proc.call( [ '*' ] ) ).to eql( false )
      expect( @proc.call( [ ' !' ] ) ).to eql( false )
      expect( @proc.call( [ '! ' ] ) ).to eql( false )
      expect( @proc.call( [ "!\n" ] ) ).to eql( false )
      expect( @proc.call( 42 ) ).to eql( false )
      expect( @proc.call( { :hello => :world } ) ).to eql( false )
    end

    it 'rescues' do
      expect( @proc.call( TestRescueAllMatchersObject.new ) ).to eql( false )
    end
  end

  context '::matches_wildcard' do
    let( :param ) { '^..!.*' }
    let( :proc  ) { Hoodoo::ActiveRecord::Finder::SecurityHelper.matches_wildcard( param ) }

    shared_examples 'a ::matches_wildcard Proc' do
      it 'and matches when it should' do
        expect( proc().call( '12!' ) ).to eql( true )
        expect( proc().call( '12!3' ) ).to eql( true )

        if ''.respond_to?( :match? )
          expect( proc().call( TestAllMatchersObject.new ) ).to eql( true )
        else
          expect_any_instance_of( Regexp ).to receive( :match ).and_return( true )
          proc().call( TestAllMatchersObject.new )
        end
      end

      it 'and misses when it should' do
        expect( proc().call( '123!4' ) ).to eql( false )
        expect( proc().call( '1!4' ) ).to eql( false )
        expect( proc().call( 42 ) ).to eql( false )
        expect( proc().call( { :hello => :world } ) ).to eql( false )
        expect( proc().call( [ 1, 2, 3, 4 ] ) ).to eql( false )
      end

      it 'and rescues' do
        if ''.respond_to?( :match? )
          expect( proc().call( TestRescueAllMatchersObject.new ) ).to eql( false )
        else
          expect_any_instance_of( Regexp ).to receive( :match ).and_raise( RuntimeError )
          proc().call( TestRescueAllMatchersObject.new )
        end
      end
    end

    # Tests running on Ruby >= 2.4 need String#match? knocking out for a
    # while, for code coverage.
    #
    context 'with slow matcher' do
      before :each do
        @unbound_method = String.instance_method( :match? )
        String.send( :remove_method, :match? )
      end

      after :each do
        String.send( :define_method, :match?, @unbound_method )
      end

      context 'constructed with a String' do
        it_behaves_like 'a ::matches_wildcard Proc'
      end

      context 'constructed with a Regexp' do
        let( :param ) { /^..!.*/ }
        it_behaves_like 'a ::matches_wildcard Proc'
      end
    end

    # Tests running on Ruby < 2.4 can't do the fast match tests.
    #
    if ''.respond_to?( :match? )
      context 'with fast matcher' do
        context 'constructed with a String' do
          it_behaves_like 'a ::matches_wildcard Proc'
        end

        context 'constructed with a Regexp' do
          let( :param ) { /^..!.*/ }
          it_behaves_like 'a ::matches_wildcard Proc'
        end
      end
    end
  end

  context '::matches_wildcard_enumerable' do
    let( :proc  ) { Hoodoo::ActiveRecord::Finder::SecurityHelper.matches_wildcard_enumerable( param ) }
    let( :param ) { '^..!.*' }

    shared_examples 'a ::matches_wildcard Proc' do
      it 'and matches when it should' do
        expect( proc().call( [ '12!34', '1', 2, :three, 4 ] ) ).to eql( true )
        expect( proc().call( [ '1', 2, :three, '12!34', 4 ] ) ).to eql( true )
        expect( proc().call( [ '1', 2, :three, 4, '12!34' ] ) ).to eql( true )
        expect( proc().call( [ '12!' ] ) ).to eql( true )

        if ''.respond_to?( :match? )
          expect( proc().call( [ TestAllMatchersObject.new ] ) ).to eql( true )
        else
          expect_any_instance_of( Regexp ).to receive( :match ).and_return( true )
          proc().call( [ TestAllMatchersObject.new ] )
        end
      end

      it 'and misses when it should' do
        expect( proc().call( [ '123!34' ] ) ).to eql( false )
        expect( proc().call( [ '1!4' ] ) ).to eql( false )
        expect( proc().call( { :hello => :world } ) ).to eql( false )
        expect( proc().call( [ 1, 2, 3, 4 ] ) ).to eql( false )
      end

      it 'and rescues' do
        expect( proc().call( 42 ) ).to eql( false )

        if ''.respond_to?( :match? )
          expect( proc().call( [ TestRescueAllMatchersObject.new ] ) ).to eql( false )
        else
          expect_any_instance_of( Regexp ).to receive( :match ).and_raise( RuntimeError )
          proc().call( [ TestRescueAllMatchersObject.new ] )
        end
      end
    end

    context 'constructed with a String' do
      it_behaves_like 'a ::matches_wildcard Proc'
    end

    context 'constructed with a Regexp' do
      let( :param ) { /^..!.*/ }
      it_behaves_like 'a ::matches_wildcard Proc'
    end
  end
end
