require 'spec_helper'

describe Hoodoo::ActiveRecord::Finder::SearchHelper do

  # Note all tests check that when no input parameter is given, the
  # returned Proc obeys the first passed argument, using it in the query.
  # This is in case callers decide to re-use a Proc for other searches; it
  # might happen, and they'd break unless the inbound field attribute was
  # being honoured.
  #
  # Obviously, when passed a parameter, the model attribute name is being
  # explicitly specified so this cannot be used for something else and the
  # Proc's first argument is intentionally ignored.

  context '#cs_match' do
    it 'generates expected no-input-parameter output' do
      result = described_class.cs_match
      expect( result.call( 'a', 'b' ) ).to eq( [ { 'a' => 'b' } ] )
    end

    it 'generates expected one-input-parameter output' do
      result = described_class.cs_match( :bar )
      expect( result.call( 'a', 'b' ) ).to eq( [ { :bar => 'b' } ] )
    end
  end

  context '#cs_match_csv' do
    it 'generates expected no-input-parameter output' do
      result = described_class.cs_match_csv()
      expect( result.call( 'a', 'b,c,d' ) ).to eq( [ { 'a' => [ 'b', 'c', 'd' ] } ] )
    end

    it 'generates expected one-input-parameter output' do
      result = described_class.cs_match_csv( :bar )
      expect( result.call( 'a', 'b,c,d' ) ).to eq( [ { :bar => [ 'b', 'c', 'd' ] } ] )
    end
  end

  context '#cs_match_array' do
    it 'generates expected no-input-parameter output' do
      result = described_class.cs_match_array()
      expect( result.call( 'a', [ 'b', 'c', 'd' ] ) ).to eq( [ { 'a' => [ 'b', 'c', 'd' ] } ] )
    end

    it 'generates expected one-input-parameter output' do
      result = described_class.cs_match_array( :bar )
      expect( result.call( 'a', [ 'b', 'c', 'd' ] ) ).to eq( [ { :bar => [ 'b', 'c', 'd' ] } ] )
    end
  end

  context '#ci_match_generic' do
    it 'generates expected no-input-parameter output' do
      result = described_class.ci_match_generic()
      expect( result.call( 'a', 'b' ) ).to eq( [ 'lower(a) = ?', 'b' ] )
    end

    it 'generates expected one-input-parameter output' do
      result = described_class.ci_match_generic( :bar )
      expect( result.call( 'a', 'b' ) ).to eq( [ 'lower(bar) = ?', 'b' ] )
    end
  end

  context '#ciaw_match_generic' do
    it 'generates expected no-input-parameter output' do
      result = described_class.ciaw_match_generic()
      expect( result.call( 'a', 'b' ) ).to eq( [ 'lower(a) LIKE ?', '%b%' ] )
    end

    it 'generates expected one-input-parameter output' do
      result = described_class.ciaw_match_generic( :bar )
      expect( result.call( 'a', 'b' ) ).to eq( [ 'lower(bar) LIKE ?', '%b%' ] )
    end
  end

  context '#ci_match_postgres' do
    it 'generates expected no-input-parameter output' do
      result = described_class.ci_match_postgres()
      expect( result.call( 'a', 'b' ) ).to eq( [ 'a ILIKE ?', 'b' ] )
    end

    it 'generates expected one-input-parameter output' do
      result = described_class.ci_match_postgres( :bar )
      expect( result.call( 'a', 'b' ) ).to eq( [ 'bar ILIKE ?', 'b' ] )
    end
  end

  context '#ciaw_match_postgres' do
    it 'generates expected no-input-parameter output' do
      result = described_class.ciaw_match_postgres()
      expect( result.call( 'a', 'b' ) ).to eq( [ 'a ILIKE ?', '%b%' ] )
    end

    it 'generates expected one-input-parameter output' do
      result = described_class.ciaw_match_postgres( :bar )
      expect( result.call( 'a', 'b' ) ).to eq( [ 'bar ILIKE ?', '%b%' ] )
    end
  end
end
