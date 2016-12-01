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
  #
  # All tests also check that 'nil' values are matched in the manner
  # documented by the SearchHelper RDoc information.

  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_search_helper_tests ) do | t |
        t.text :field
        t.timestamps
      end
    end

    class RSpecModelSearchHelperTest < ActiveRecord::Base
    end
  end

  def find( clause )
    RSpecModelSearchHelperTest.where( *clause ).all
  end

  def find_not( clause )
    RSpecModelSearchHelperTest.where.not( *clause ).all
  end

  #############################################################################
  # Although the queries in this section can match things other than strings
  # in some cases, they're aimed at string comparison most of the time.
  #############################################################################

  context 'equality' do
    before :each do
      @f1 = RSpecModelSearchHelperTest.create
      @f2 = RSpecModelSearchHelperTest.create( :field => 'hello' )
      @f3 = RSpecModelSearchHelperTest.create( :field => 'hello' )
      @f4 = RSpecModelSearchHelperTest.create( :field => 'HELLO' )
      @f5 = RSpecModelSearchHelperTest.create
      @f6 = RSpecModelSearchHelperTest.create( :field => 'world' )
      @f7 = RSpecModelSearchHelperTest.create( :field => 'world' )
      @f8 = RSpecModelSearchHelperTest.create( :field => 'WORLD' )
    end

    ###########################################################################

    context '#cs_match' do
      it 'generates expected no-input-parameter output' do
        result = described_class.cs_match
        expect( result.call( 'a', 'b' ) ).to eq( [ 'a = ? AND a IS NOT NULL', 'b' ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.cs_match( :bar )
        expect( result.call( 'a', 'b' ) ).to eq( [ 'bar = ? AND bar IS NOT NULL', 'b' ] )
      end

      it 'finds expected things' do
        result = find( described_class.cs_match.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f2, @f3 ] )

        result = find( described_class.cs_match.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f4 ] )

        result = find( described_class.cs_match.call( 'field', 'hell' ) )
        expect( result ).to match_array( [] )

        result = find( described_class.cs_match.call( 'field', 'llo' ) )
        expect( result ).to match_array( [] )

        result = find( described_class.cs_match.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.cs_match.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f1,           @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.cs_match.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3,      @f5, @f6, @f7, @f8  ] )

        result = find_not( described_class.cs_match.call( 'field', 'hell' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.cs_match.call( 'field', 'llo' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.cs_match.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )
      end
    end

    ###########################################################################

    context '#cs_match_csv' do
      it 'generates expected no-input-parameter output' do
        result = described_class.cs_match_csv()
        expect( result.call( 'a', 'b,c,d' ) ).to eq( [ 'a IN (?) AND a IS NOT NULL', [ 'b', 'c', 'd' ] ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.cs_match_csv( :bar )
        expect( result.call( 'a', 'b,c,d' ) ).to eq( [ 'bar IN (?) AND bar IS NOT NULL', [ 'b', 'c', 'd' ] ] )
      end

      it 'finds expected things' do
        result = find( described_class.cs_match_csv.call( 'field', 'hello,world' ) )
        expect( result ).to match_array( [ @f2, @f3, @f6, @f7 ] )

        result = find( described_class.cs_match_csv.call( 'field', 'HELLO,WORLD' ) )
        expect( result ).to match_array( [ @f4, @f8 ] )

        result = find( described_class.cs_match_csv.call( 'field', 'hell,worl' ) )
        expect( result ).to match_array( [] )

        result = find( described_class.cs_match_csv.call( 'field', 'llo,ld' ) )
        expect( result ).to match_array( [] )

        result = find( described_class.cs_match_csv.call( 'field', 'heLLo,WORld' ) )
        expect( result ).to match_array( [] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.cs_match_csv.call( 'field', 'hello,world' ) )
        expect( result ).to match_array( [ @f1,           @f4, @f5,          @f8 ] )

        result = find_not( described_class.cs_match_csv.call( 'field', 'HELLO,WORLD' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3,      @f5, @f6, @f7      ] )

        result = find_not( described_class.cs_match_csv.call( 'field', 'hell,worl' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.cs_match_csv.call( 'field', 'llo,ld' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.cs_match_csv.call( 'field', 'heLLo,WORld' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )
      end
    end

    ###########################################################################

    context '#cs_match_array' do
      it 'generates expected no-input-parameter output' do
        result = described_class.cs_match_array()
        expect( result.call( 'a', [ 'b', 'c', 'd' ] ) ).to eq( [ 'a IN (?) AND a IS NOT NULL', [ 'b', 'c', 'd' ] ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.cs_match_array( :bar )
        expect( result.call( 'a', [ 'b', 'c', 'd' ] ) ).to eq( [ 'bar IN (?) AND bar IS NOT NULL', [ 'b', 'c', 'd' ] ] )
      end

      it 'finds expected things' do
        result = find( described_class.cs_match_array.call( 'field', [ 'hello', 'world' ] ) )
        expect( result ).to match_array( [ @f2, @f3, @f6, @f7 ] )

        result = find( described_class.cs_match_array.call( 'field', [ 'HELLO', 'WORLD' ] ) )
        expect( result ).to match_array( [ @f4, @f8 ] )

        result = find( described_class.cs_match_array.call( 'field', [ 'hell', 'worl' ] ) )
        expect( result ).to match_array( [] )

        result = find( described_class.cs_match_array.call( 'field', [ 'llo', 'ld' ] ) )
        expect( result ).to match_array( [] )

        result = find( described_class.cs_match_array.call( 'field', [ 'heLLo', 'WORld' ] ) )
        expect( result ).to match_array( [] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.cs_match_array.call( 'field', [ 'hello', 'world' ] ) )
        expect( result ).to match_array( [ @f1,           @f4, @f5,          @f8 ] )

        result = find_not( described_class.cs_match_array.call( 'field', [ 'HELLO', 'WORLD' ] ) )
        expect( result ).to match_array( [ @f1, @f2, @f3,      @f5, @f6, @f7      ] )

        result = find_not( described_class.cs_match_array.call( 'field', [ 'hell', 'worl' ] ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.cs_match_array.call( 'field', [ 'llo', 'ld' ] ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.cs_match_array.call( 'field', [ 'heLLo', 'WORld' ] ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )
      end
    end

    ###########################################################################

    context '#ci_match_generic' do
      it 'generates expected no-input-parameter output' do
        result = described_class.ci_match_generic()
        expect( result.call( 'a', 'B' ) ).to eq( [ 'lower(a) = ? AND a IS NOT NULL', 'b' ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.ci_match_generic( :bar )
        expect( result.call( 'a', 'B' ) ).to eq( [ 'lower(bar) = ? AND bar IS NOT NULL', 'b' ] )
      end

      it 'finds expected things' do
        result = find( described_class.ci_match_generic.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ci_match_generic.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ci_match_generic.call( 'field', 'hell' ) )
        expect( result ).to match_array( [] )

        result = find( described_class.ci_match_generic.call( 'field', 'llo' ) )
        expect( result ).to match_array( [] )

        result = find( described_class.ci_match_generic.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.ci_match_generic.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f1,                @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ci_match_generic.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f1,                @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ci_match_generic.call( 'field', 'hell' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ci_match_generic.call( 'field', 'llo' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ci_match_generic.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [ @f1,                @f5, @f6, @f7, @f8 ] )
      end
    end

    ###########################################################################

    context '#ciaw_match_generic' do
      it 'generates expected no-input-parameter output' do
        result = described_class.ciaw_match_generic()
        expect( result.call( 'a', 'B' ) ).to eq( [ 'lower(a) LIKE ? AND a IS NOT NULL', '%b%' ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.ciaw_match_generic( :bar )
        expect( result.call( 'a', 'B' ) ).to eq( [ 'lower(bar) LIKE ? AND bar IS NOT NULL', '%b%' ] )
      end

      it 'finds expected things' do
        result = find( described_class.ciaw_match_generic.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ciaw_match_generic.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ciaw_match_generic.call( 'field', 'hell' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ciaw_match_generic.call( 'field', 'llo' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ciaw_match_generic.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.ciaw_match_generic.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f1, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ciaw_match_generic.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f1, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ciaw_match_generic.call( 'field', 'hell' ) )
        expect( result ).to match_array( [ @f1, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ciaw_match_generic.call( 'field', 'llo' ) )
        expect( result ).to match_array( [ @f1, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ciaw_match_generic.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [ @f1, @f5, @f6, @f7, @f8 ] )
      end
    end

    ###########################################################################

    context '#csaw_match' do
      it 'generates expected no-input-parameter output' do
        result = described_class.csaw_match()
        expect( result.call( 'a', 'B' ) ).to eq( [ 'a LIKE ? AND a IS NOT NULL', '%B%' ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.csaw_match( :bar )
        expect( result.call( 'a', 'B' ) ).to eq( [ 'bar LIKE ? AND bar IS NOT NULL', '%B%' ] )
      end

      it 'finds expected things' do
        result = find( described_class.csaw_match.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f2, @f3 ] )

        result = find( described_class.csaw_match.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f4 ] )

        result = find( described_class.csaw_match.call( 'field', 'hell' ) )
        expect( result ).to match_array( [ @f2, @f3 ] )

        result = find( described_class.csaw_match.call( 'field', 'llo' ) )
        expect( result ).to match_array( [ @f2, @f3 ] )

        result = find( described_class.csaw_match.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [  ] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.csaw_match.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f1, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.csaw_match.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.csaw_match.call( 'field', 'hell' ) )
        expect( result ).to match_array( [ @f1, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.csaw_match.call( 'field', 'llo' ) )
        expect( result ).to match_array( [ @f1, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.csaw_match.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )
      end
    end

    ###########################################################################

    context '#ci_match_postgres' do
      it 'generates expected no-input-parameter output' do
        result = described_class.ci_match_postgres()
        expect( result.call( 'a', 'B' ) ).to eq( [ 'a ILIKE ? AND a IS NOT NULL', 'B' ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.ci_match_postgres( :bar )
        expect( result.call( 'a', 'B' ) ).to eq( [ 'bar ILIKE ? AND bar IS NOT NULL', 'B' ] )
      end

      it 'finds expected things' do
        result = find( described_class.ci_match_postgres.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ci_match_postgres.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ci_match_postgres.call( 'field', 'hell' ) )
        expect( result ).to match_array( [] )

        result = find( described_class.ci_match_postgres.call( 'field', 'llo' ) )
        expect( result ).to match_array( [] )

        result = find( described_class.ci_match_postgres.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.ci_match_postgres.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f1,                @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ci_match_postgres.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f1,                @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ci_match_postgres.call( 'field', 'hell' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ci_match_postgres.call( 'field', 'llo' ) )
        expect( result ).to match_array( [ @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ci_match_postgres.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [ @f1,                @f5, @f6, @f7, @f8 ] )
      end
    end

    ###########################################################################

    context '#ciaw_match_postgres' do
      it 'generates expected no-input-parameter output' do
        result = described_class.ciaw_match_postgres()
        expect( result.call( 'a', 'B' ) ).to eq( [ 'a ILIKE ? AND a IS NOT NULL', '%B%' ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.ciaw_match_postgres( :bar )
        expect( result.call( 'a', 'B' ) ).to eq( [ 'bar ILIKE ? AND bar IS NOT NULL', '%B%' ] )
      end

      it 'finds expected things' do
        result = find( described_class.ciaw_match_postgres.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ciaw_match_postgres.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ciaw_match_postgres.call( 'field', 'hell' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ciaw_match_postgres.call( 'field', 'llo' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )

        result = find( described_class.ciaw_match_postgres.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [ @f2, @f3, @f4 ] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.ciaw_match_postgres.call( 'field', 'hello' ) )
        expect( result ).to match_array( [ @f1, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ciaw_match_postgres.call( 'field', 'HELLO' ) )
        expect( result ).to match_array( [ @f1, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ciaw_match_postgres.call( 'field', 'hell' ) )
        expect( result ).to match_array( [ @f1, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ciaw_match_postgres.call( 'field', 'llo' ) )
        expect( result ).to match_array( [ @f1, @f5, @f6, @f7, @f8 ] )

        result = find_not( described_class.ciaw_match_postgres.call( 'field', 'heLLo' ) )
        expect( result ).to match_array( [ @f1, @f5, @f6, @f7, @f8 ] )
      end
    end

    ###########################################################################

  end

  #############################################################################
  # Although the queries in this section can match things other than dates
  # easily - e.g. compare integers or strings - they were created initially
  # for date comparisons so the seed data for tests is based on dates only.
  #############################################################################

  context 'difference' do
    before :each do
      @tn = Time.now.round()
      @t1 = RSpecModelSearchHelperTest.create( :created_at => @tn           )
      @t2 = RSpecModelSearchHelperTest.create( :created_at => @tn           )
      @t3 = RSpecModelSearchHelperTest.create( :created_at => @tn - 1.month )
      @t4 = RSpecModelSearchHelperTest.create( :created_at => @tn - 1.month )
      @t5 = RSpecModelSearchHelperTest.create( :created_at => @tn - 1.year  )
      @t6 = RSpecModelSearchHelperTest.create( :created_at => @tn - 1.year  )
      @t7 = RSpecModelSearchHelperTest.create

      sql = "UPDATE r_spec_model_search_helper_tests SET created_at=NULL WHERE id=#{ @t7.id }"
      ActiveRecord::Base.connection.execute( sql )
    end

    ###########################################################################

    context '#cs_lt' do
      it 'generates expected no-input-parameter output' do
        result = described_class.cs_lt()
        expect( result.call( 'a', 'b' ) ).to eq( [ 'a < ? AND a IS NOT NULL', 'b' ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.cs_lt( :bar )
        expect( result.call( 'a', 'b' ) ).to eq( [ 'bar < ? AND bar IS NOT NULL', 'b' ] )
      end

      it 'finds expected things' do
        result = find( described_class.cs_lt.call( 'created_at', @tn ) )
        expect( result ).to match_array( [ @t3, @t4, @t5, @t6 ] )

        result = find( described_class.cs_lt.call( 'created_at', ( @tn - 2.months ) ) )
        expect( result ).to match_array( [ @t5, @t6 ] )

        result = find( described_class.cs_lt.call( 'created_at', ( @tn + 1.month ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t5, @t6 ] )

        result = find( described_class.cs_lt.call( 'created_at', ( @tn - 1.year ) ) )
        expect( result ).to match_array( [] )

        result = find( described_class.cs_lt.call( 'created_at', ( @tn - 2.years ) ) )
        expect( result ).to match_array( [] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.cs_lt.call( 'created_at', @tn ) )
        expect( result ).to match_array( [ @t1, @t2, @t7 ] )

        result = find_not( described_class.cs_lt.call( 'created_at', ( @tn - 2.months ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t7 ] )

        result = find_not( described_class.cs_lt.call( 'created_at', ( @tn + 1.month ) ) )
        expect( result ).to match_array( [ @t7 ] )

        result = find_not( described_class.cs_lt.call( 'created_at', ( @tn - 1.year ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t5, @t6, @t7 ] )

        result = find_not( described_class.cs_lt.call( 'created_at', ( @tn - 2.years ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t5, @t6, @t7 ] )
      end
    end

    ###########################################################################

    context '#cs_lte' do
      it 'generates expected no-input-parameter output' do
        result = described_class.cs_lte()
        expect( result.call( 'a', 'b' ) ).to eq( [ 'a <= ? AND a IS NOT NULL', 'b' ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.cs_lte( :bar )
        expect( result.call( 'a', 'b' ) ).to eq( [ 'bar <= ? AND bar IS NOT NULL', 'b' ] )
      end

      it 'finds expected things' do
        result = find( described_class.cs_lte.call( 'created_at', @tn ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t5, @t6 ] )

        result = find( described_class.cs_lte.call( 'created_at', ( @tn - 2.months ) ) )
        expect( result ).to match_array( [ @t5, @t6 ] )

        result = find( described_class.cs_lte.call( 'created_at', ( @tn + 1.month ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t5, @t6 ] )

        result = find( described_class.cs_lte.call( 'created_at', ( @tn - 1.year ) ) )
        expect( result ).to match_array( [ @t5, @t6 ] )

        result = find( described_class.cs_lte.call( 'created_at', ( @tn - 2.years ) ) )
        expect( result ).to match_array( [] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.cs_lte.call( 'created_at', @tn ) )
        expect( result ).to match_array( [ @t7 ] )

        result = find_not( described_class.cs_lte.call( 'created_at', ( @tn - 2.months ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t7 ] )

        result = find_not( described_class.cs_lte.call( 'created_at', ( @tn + 1.month ) ) )
        expect( result ).to match_array( [ @t7 ] )

        result = find_not( described_class.cs_lte.call( 'created_at', ( @tn - 1.year ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t7 ] )

        result = find_not( described_class.cs_lte.call( 'created_at', ( @tn - 2.years ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t5, @t6, @t7 ] )
      end
    end

    ###########################################################################

    context '#cs_gt' do
      it 'generates expected no-input-parameter output' do
        result = described_class.cs_gt()
        expect( result.call( 'a', 'b' ) ).to eq( [ 'a > ? AND a IS NOT NULL', 'b' ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.cs_gt( :bar )
        expect( result.call( 'a', 'b' ) ).to eq( [ 'bar > ? AND bar IS NOT NULL', 'b' ] )
      end

      it 'finds expected things' do
        result = find( described_class.cs_gt.call( 'created_at', @tn ) )
        expect( result ).to match_array( [] )

        result = find( described_class.cs_gt.call( 'created_at', ( @tn - 2.months ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4 ] )

        result = find( described_class.cs_gt.call( 'created_at', ( @tn - 1.month ) ) )
        expect( result ).to match_array( [ @t1, @t2 ] )

        result = find( described_class.cs_gt.call( 'created_at', ( @tn - 1.year ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4 ] )

        result = find( described_class.cs_gt.call( 'created_at', ( @tn - 2.years ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t5, @t6 ] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.cs_gt.call( 'created_at', @tn ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t5, @t6, @t7 ] )

        result = find_not( described_class.cs_gt.call( 'created_at', ( @tn - 2.months ) ) )
        expect( result ).to match_array( [ @t5, @t6, @t7 ] )

        result = find_not( described_class.cs_gt.call( 'created_at', ( @tn - 1.month ) ) )
        expect( result ).to match_array( [ @t3, @t4, @t5, @t6, @t7 ] )

        result = find_not( described_class.cs_gt.call( 'created_at', ( @tn - 1.year ) ) )
        expect( result ).to match_array( [ @t5, @t6, @t7 ] )

        result = find_not( described_class.cs_gt.call( 'created_at', ( @tn - 2.years ) ) )
        expect( result ).to match_array( [ @t7 ] )
      end
    end

    ###########################################################################

    context '#cs_gte' do
      it 'generates expected no-input-parameter output' do
        result = described_class.cs_gte()
        expect( result.call( 'a', 'b' ) ).to eq( [ 'a >= ? AND a IS NOT NULL', 'b' ] )
      end

      it 'generates expected one-input-parameter output' do
        result = described_class.cs_gte( :bar )
        expect( result.call( 'a', 'b' ) ).to eq( [ 'bar >= ? AND bar IS NOT NULL', 'b' ] )
      end

      it 'finds expected things' do
        result = find( described_class.cs_gte.call( 'created_at', @tn ) )
        expect( result ).to match_array( [ @t1, @t2 ] )

        result = find( described_class.cs_gte.call( 'created_at', ( @tn - 2.months ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4 ] )

        result = find( described_class.cs_gte.call( 'created_at', ( @tn - 1.month ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4 ] )

        result = find( described_class.cs_gte.call( 'created_at', ( @tn - 1.year ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t5, @t6 ] )

        result = find( described_class.cs_gte.call( 'created_at', ( @tn - 2.years ) ) )
        expect( result ).to match_array( [ @t1, @t2, @t3, @t4, @t5, @t6 ] )
      end

      it 'finds expected things negated' do
        result = find_not( described_class.cs_gte.call( 'created_at', @tn ) )
        expect( result ).to match_array( [ @t3, @t4, @t5, @t6, @t7 ] )

        result = find_not( described_class.cs_gte.call( 'created_at', ( @tn - 2.months ) ) )
        expect( result ).to match_array( [ @t5, @t6, @t7 ] )

        result = find_not( described_class.cs_gte.call( 'created_at', ( @tn - 1.month ) ) )
        expect( result ).to match_array( [ @t5, @t6, @t7 ] )

        result = find_not( described_class.cs_gte.call( 'created_at', ( @tn - 1.year ) ) )
        expect( result ).to match_array( [ @t7 ] )

        result = find_not( described_class.cs_gte.call( 'created_at', ( @tn - 2.years ) ) )
        expect( result ).to match_array( [ @t7 ] )
      end
    end

    ###########################################################################

  end
end
