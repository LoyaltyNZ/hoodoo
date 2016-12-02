require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Finder do
  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_finder_tests, :id => false ) do | t |
        t.text :id
        t.text :uuid
        t.text :code
        t.text :field_one
        t.text :field_two
        t.text :field_three

        t.timestamps
      end
    end

    class RSpecModelFinderTest < ActiveRecord::Base
      include Hoodoo::ActiveRecord::Finder

      self.primary_key = :id
      acquire_with :uuid, :code, :uuid # Deliberate duplication

      # These forms follow quite closely the RDoc comments in
      # the finder.rb source.

      ARRAY_MATCH = Proc.new { | attr, value |
        [ { attr => [ value ].flatten } ]
      }

      # Pretend security scoping that only finds things with
      # a UUID and code coming in from the session, for secured
      # searches. Note intentional mix of Symbols and Strings.

      secure_with(
        'uuid' => :authorised_uuids, # Array
        :code => 'authorised_code'   # Single item
      )

      # Deliberate mixture of symbols and strings.

      search_with(
        'field_one' => nil,
        :field_two => Proc.new { | attr, value |
          [ "#{ attr } ILIKE ?", value ]
        },
        :field_three => ARRAY_MATCH
      )

      filter_with(
        :field_one => ARRAY_MATCH,
        :field_two => nil,
        'field_three' => Proc.new { | attr, value |
          [ "#{ attr } ILIKE ?", value ]
        }
      )
    end

    class RSpecModelFinderTestWithDating < ActiveRecord::Base
      self.primary_key = :id
      self.table_name = :r_spec_model_finder_tests

      include Hoodoo::ActiveRecord::Finder
      include Hoodoo::ActiveRecord::Dated
    end

    class RSpecModelFinderTestWithHelpers < ActiveRecord::Base
      include Hoodoo::ActiveRecord::Finder

      self.primary_key = :id

      self.table_name = :r_spec_model_finder_tests
      sh              = Hoodoo::ActiveRecord::Finder::SearchHelper

      search_with(
        'mapped_code'     => sh.cs_match( 'code' ),
        :mapped_field_one => sh.ci_match_generic( 'field_one' ),
        :wild_field_one   => sh.ciaw_match_generic( 'field_one '),
        :field_two        => sh.cs_match_csv(),
        'field_three'     => sh.cs_match_array()
      )

      filter_with(
        'mapped_code'     => sh.cs_match( 'code' ),
        :mapped_field_one => sh.ci_match_postgres( 'field_one' ),
        :wild_field_one   => sh.ciaw_match_postgres( 'field_one '),
        :field_two        => sh.cs_match_csv(),
        'field_three'     => sh.cs_match_array()
      )
    end
  end

  before :each do
    @tn = Time.now.round()

    @a = RSpecModelFinderTest.new
    @a.id = "one"
    @a.code = 'A' # Must be set else SQLite fails to find this if you search for "code != 'C'" (!)
    @a.field_one = 'group 1'
    @a.field_two = 'two a'
    @a.field_three = 'three a'
    @a.created_at = @tn - 1.year
    @a.save!
    @id = @a.id

    @b = RSpecModelFinderTest.new
    @b.id = "two"
    @b.uuid = Hoodoo::UUID.generate
    @b.code = 'B'
    @b.field_one = 'group 1'
    @b.field_two = 'two b'
    @b.field_three = 'three b'
    @b.created_at = @tn - 1.month
    @b.save!
    @uuid = @b.uuid

    @c = RSpecModelFinderTest.new
    @c.id = "three"
    @c.code = 'C'
    @c.field_one = 'group 2'
    @c.field_two = 'two c'
    @c.field_three = 'three c'
    @c.created_at = @tn
    @c.save!
    @code = @c.code

    @a_wh = RSpecModelFinderTestWithHelpers.find( @a.id )
    @b_wh = RSpecModelFinderTestWithHelpers.find( @b.id )
    @c_wh = RSpecModelFinderTestWithHelpers.find( @c.id )

    @list_params = Hoodoo::Services::Request::ListParameters.new
  end

  # ==========================================================================

  context '#scoped_in' do
    before :each do

      # Get a good-enough-for-test interaction which has a context
      # that contains a Session we can modify.

      @interaction = Hoodoo::Services::Middleware::Interaction.new( {}, nil )
      @interaction.context = Hoodoo::Services::Context.new(
        Hoodoo::Services::Session.new,
        @interaction.context.request,
        @interaction.context.response,
        @interaction
      )

      @context = @interaction.context
      @session = @interaction.context.session
    end

    # If security scoping works _and_ we know that it called #full_scope_for
    # in the "internal"-ish support API, then we consider that good enough
    # to prove that it's calling the scope engine and that engine has its
    # own comprehensive test coverage in suport_spec.rb.
    #
    it 'generates appropriate scope' do
      @session.scoping = { :authorised_uuids => [ 'uuid 1', 'uuid 2' ], :authorised_code => 'code 1' }

      expect( Hoodoo::ActiveRecord::Support ).to(
        receive( :full_scope_for ).once().with(
          RSpecModelFinderTest, @context
        ).and_call_original()
      )

      sql = RSpecModelFinderTest.scoped_in( @context ).to_sql

      expect( sql ).to eq( "SELECT \"r_spec_model_finder_tests\".* " \
                           "FROM \"r_spec_model_finder_tests\" "     \
                           "WHERE "                                  \
                             "\"r_spec_model_finder_tests\".\"uuid\" IN ('uuid 1', 'uuid 2') AND " \
                             "\"r_spec_model_finder_tests\".\"code\" = 'code 1'" )
    end
  end

  # ==========================================================================

  context 'acquisition scope and overrides' do
    def expect_sql( sql, id_attr_name )
      expect( sql ).to eq( "SELECT \"r_spec_model_finder_tests\".* " \
                           "FROM \"r_spec_model_finder_tests\" "     \
                           "WHERE ("                                 \
                             "("                                     \
                               "\"r_spec_model_finder_tests\".\"#{ id_attr_name }\" = '#{ @id }' OR " \
                               "\"r_spec_model_finder_tests\".\"uuid\" = '#{ @id }'"                  \
                             ") OR "                                               \
                             "\"r_spec_model_finder_tests\".\"code\" = '#{ @id }'" \
                           ")" )
    end

    context '#acquisition_scope' do
      it 'SQL generation is as expected' do
        sql = RSpecModelFinderTest.acquisition_scope( @id ).to_sql()
        expect_sql( sql, 'id' )
      end
    end

    context '#acquire_with_id_substitute' do
      before :each do
        @alt_attr_name = 'foo'
        RSpecModelFinderTest.acquire_with_id_substitute( @alt_attr_name )
      end

      after :each do
        RSpecModelFinderTest.acquire_with_id_substitute( 'id' )
      end

      it 'SQL generation is as expected' do
        sql = RSpecModelFinderTest.acquisition_scope( @id ).to_sql()
        expect_sql( sql, @alt_attr_name )
      end
    end
  end

  # ==========================================================================

  context '#acquire' do
    it 'finds from the class' do
      found = RSpecModelFinderTest.acquire( @id )
      expect( found ).to eq(@a)

      found = RSpecModelFinderTest.acquire( @uuid )
      expect( found ).to eq(@b)

      found = RSpecModelFinderTest.acquire( @code )
      expect( found ).to eq(@c)
    end

    it 'finds with a chain' do
      finder = RSpecModelFinderTest.where( :field_one => 'group 1' )

      found = finder.acquire( @id )
      expect( found ).to eq(@a)

      found = finder.acquire( @uuid )
      expect( found ).to eq(@b)

      found = finder.acquire( @code )
      expect( found ).to eq(nil) # Not in 'group 1'
    end

    # Early versions of the 'acquire'-backed methods always inadvertently
    # performed two database calls, via a count then a true find. This was
    # refactored to only make one call per attribute, but that in turn can
    # be much improved via the AREL table to compose a single query that
    # uses "OR" to get the database to check each attribute in order. Thus
    # every test below expects exactly one database call only.
    #
    context 'only makes one database call when' do

      it 'finding on the first attribute' do
        count = count_database_calls_in do
          found = RSpecModelFinderTest.acquire( @id )
          expect( found ).to eq(@a)
        end

        expect( count ).to eq( 1 )
      end

      it 'finding on the second attribute' do
        count = count_database_calls_in do
          found = RSpecModelFinderTest.acquire( @uuid )
          expect( found ).to eq(@b)
        end

        expect( count ).to eq( 1 )
      end

      it 'finding on the third attribute' do
        count = count_database_calls_in do
          found = RSpecModelFinderTest.acquire( @code )
          expect( found ).to eq(@c)
        end

        expect( count ).to eq( 1 )
      end

      it 'checking all three attributes but finding nothing' do
        count = count_database_calls_in do
          found = RSpecModelFinderTest.acquire( Hoodoo::UUID.generate )
          expect( found ).to be_nil
        end

        expect( count ).to eq( 1 )
      end
    end
  end

  # ==========================================================================

  context '#acquire_in' do
    before :each do
      @scoped_1 = RSpecModelFinderTest.new
      @scoped_1.id        = 'id 1'
      @scoped_1.uuid      = 'uuid 1'
      @scoped_1.code      = 'code 1'
      @scoped_1.field_one = 'scoped 1'
      @scoped_1.save!

      @scoped_2 = RSpecModelFinderTest.new
      @scoped_2.id        = 'id 2'
      @scoped_2.uuid      = 'uuid 1'
      @scoped_2.code      = 'code 2'
      @scoped_2.field_one = 'scoped 2'
      @scoped_2.save!

      @scoped_3 = RSpecModelFinderTest.new
      @scoped_3.id        = 'id 3'
      @scoped_3.uuid      = 'uuid 2'
      @scoped_3.code      = 'code 2'
      @scoped_3.field_one = 'scoped 3'
      @scoped_3.save!

      # Get a good-enough-for-test interaction which has a context
      # that contains a Session we can modify.

      @interaction = Hoodoo::Services::Middleware::Interaction.new( {}, nil )
      @interaction.context = Hoodoo::Services::Context.new(
        Hoodoo::Services::Session.new,
        @interaction.context.request,
        @interaction.context.response,
        @interaction
      )

      @context = @interaction.context
      @session = @interaction.context.session
    end

    it 'knowns how to acquire' do

      # Note the corresponding 'acquire_with' used Symbols and had a
      # duplicated entry - we expect Strings and no duplicates here.
      #
      expect( RSpecModelFinderTest.acquired_with() ).to eq( [ 'uuid', 'code' ] )

    end

    it 'finds with secure scopes from the class' do
      @session.scoping = { :authorised_uuids => [ 'uuid 1' ], :authorised_code => 'code 1' }

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to eq( @scoped_1 )

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @session.scoping.authorised_code = 'code 2'

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to eq( @scoped_2 )

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @session.scoping.authorised_uuids = [ 'uuid 2' ]

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to eq( @scoped_3 )

      @session.scoping.authorised_uuids = [ 'uuid 1', 'uuid 2' ]

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to eq( @scoped_2 )

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.acquire_in( @context )
      expect( found ).to eq( @scoped_3 )
    end

    it 'finds with secure scopes with a chain' do
      @session.scoping = { :authorised_uuids => [ 'uuid 1' ], :authorised_code => 'code 1' }

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_1.field_one ).acquire_in( @context )
      expect( found ).to eq( @scoped_1 )

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_1.field_one + '!' ).acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_2.field_one ).acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_3.field_one ).acquire_in( @context )
      expect( found ).to be_nil

      @session.scoping.authorised_uuids = [ 'uuid 1', 'uuid 2' ]
      @session.scoping.authorised_code  = 'code 2'

      @context.request.uri_path_components = [ @scoped_1.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_1.field_one ).acquire_in( @context )
      expect( found ).to be_nil

      @context.request.uri_path_components = [ @scoped_2.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_2.field_one ).acquire_in( @context )
      expect( found ).to eq( @scoped_2 )

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_3.field_one ).acquire_in( @context )
      expect( found ).to eq( @scoped_3 )

      @context.request.uri_path_components = [ @scoped_3.id ]
      found = RSpecModelFinderTest.where( :field_one => @scoped_3.field_one + '!' ).acquire_in( @context )
      expect( found ).to be_nil
    end
  end

  # ==========================================================================

  context '#list' do
    it 'lists with pages, offsets and counts' do
      expect_any_instance_of( RSpecModelFinderTest ).to_not receive( :estimated_dataset_size )

      @list_params.offset = 1 # 0 is first record
      @list_params.limit  = 1

      finder = RSpecModelFinderTest.order( :field_three => :asc ).list( @list_params )
      expect( finder ).to eq([@b])
      expect( finder.dataset_size).to eq(3)

      @list_params.offset = 1
      @list_params.limit  = 2

      finder = RSpecModelFinderTest.order( :field_three => :asc ).list( @list_params )
      expect( finder ).to eq([@b, @c])
      expect( finder.dataset_size).to eq(3)
    end
  end

  # ==========================================================================

  context 'counting' do
    it 'lists with a normal count' do
      finder = RSpecModelFinderTest.list( @list_params )

      expect( finder ).to receive( :dataset_size ).at_least( :once ).and_call_original
      expect( finder ).to receive( :count        ).at_least( :once ).and_call_original

      expect( finder ).to_not receive( :estimated_dataset_size )
      expect( finder ).to_not receive( :estimated_count        )

      result = finder.dataset_size()

      expect( result ).to_not be_nil
    end

    it 'lists with an estimated count' do
      finder = RSpecModelFinderTest.list( @list_params )

      expect( finder ).to_not receive( :dataset_size )

      expect( finder ).to receive( :estimated_dataset_size ).at_least( :once ).and_call_original
      expect( finder ).to receive( :estimated_count        ).at_least( :once ).and_call_original
      expect( finder ).to receive( :count                  ).at_least( :once ).and_call_original

      result = finder.estimated_dataset_size

      expect( result ).to_not be_nil
    end

    context 'RDoc-recommended PostgreSQL migration example' do
      before :each do
        ActiveRecord::Base.connection.execute <<-SQL
          CREATE FUNCTION estimated_count(query text) RETURNS integer AS
          $func$
          DECLARE
              rec  record;
              rows integer;
          BEGIN
              FOR rec IN EXECUTE 'EXPLAIN ' || query LOOP
                  rows := substring(rec."QUERY PLAN" FROM ' rows=([[:digit:]]+)');
                  EXIT WHEN rows IS NOT NULL;
              END LOOP;

              RETURN rows;
          END
          $func$ LANGUAGE plpgsql;
        SQL

        counter = Proc.new do | sql |
          begin
            ActiveRecord::Base.connection.execute(
              "SELECT estimated_count('#{ sql}')"
            ).first[ 'estimated_count' ].to_i
          rescue
            nil
          end
        end

        RSpecModelFinderTest.estimate_counts_with( counter )

        # Tests start by ensuring the database knows about the current object count.
        #
        ActiveRecord::Base.connection.execute( 'ANALYZE' )
      end

      after :each do
        ActiveRecord::Base.connection.execute "DROP FUNCTION estimated_count(query text);"
        RSpecModelFinderTest.estimate_counts_with( nil )
      end

      # These must run in order else e.g. the ANALYZE might happen before the
      # pre-ANALYZE test, breaking the results.
      #
      context 'estimate', :order => :defined do
        before :each do
          @initial_count = RSpecModelFinderTest.count

          # The outer 'before' code ensures an accurate initial count of 3,
          # but we're going add in a few more unestimated items.
          #
          @uncounted1 = RSpecModelFinderTest.new.save!
          @uncounted2 = RSpecModelFinderTest.new.save!
          @uncounted3 = RSpecModelFinderTest.new.save!

          @subsequent_accurate_count = RSpecModelFinderTest.count
        end

        it 'may be initially inaccurate' do
          finder = RSpecModelFinderTest.list( @list_params )
          result = finder.estimated_dataset_size
          expect( result ).to eq( @initial_count ).or( eq( @subsequent_accurate_count ) )
        end

        # The outer 'before' code kind of already tests this anyway since if
        # the analyze call therein didn't work, prerequisites in the tests
        # would be wrong and other tests would fail. It's useful to
        # double-check something this important though.
        #
        it 'is accurate after ANALYZE' do
          ActiveRecord::Base.connection.execute( 'ANALYZE' )

          finder = RSpecModelFinderTest.list( @list_params )
          result = finder.estimated_dataset_size
          expect( result ).to eq( @subsequent_accurate_count )
        end

        it 'is "nil" if the Proc evaluates thus' do
          RSpecModelFinderTest.estimate_counts_with( Proc.new() { | sql | nil } )
          finder = RSpecModelFinderTest.list( @list_params )
          result = finder.estimated_dataset_size
          expect( result ).to be_nil
        end
      end
    end
  end

  # ==========================================================================

  context 'search' do
    it 'searches without chain' do
      @list_params.search_data = {
        'field_one' => 'group 1'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@b, @a])

      @list_params.search_data = {
        'field_one' => 'group 2'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@c])

      @list_params.search_data = {
        'field_two' => 'TWO_A'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@a])

      @list_params.search_data = {
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@c, @a])

      @list_params.search_data = {
        'field_two' => 'two c',
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@c])

      @list_params.search_data = {
        'created_after' => @tn - 1.month
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@c])

      @list_params.search_data = {
        'created_on_or_before' => @tn - 1.month
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@b, @a])
    end

    it 'searches with chain' do
      constraint = RSpecModelFinderTest.where( :field_one => 'group 1' )

      @list_params.search_data = {
        'field_one' => 'group 1'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([@b, @a])

      @list_params.search_data = {
        'field_one' => 'group 2'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.search_data = {
        'field_two' => 'TWO_A'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([@a])

      @list_params.search_data = {
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([@a])

      @list_params.search_data = {
        'field_two' => 'two c',
        'field_three' => [ 'three a', 'three c' ]
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.search_data = {
        'created_after' => @tn - 1.month
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.search_data = {
        'created_on_or_before' => @tn - 1.month
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([@b, @a])
    end
  end

  # ==========================================================================

  context 'helper-based search' do
    it 'finds by mapped code' do
      @list_params.search_data = {
        'mapped_code' => @code
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [ @c_wh ] )
    end

    it 'finds by mapped field-one' do
      @list_params.search_data = {
        'mapped_field_one' => :'grOUp 1'
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [ @b_wh, @a_wh ] )
    end

    it 'finds by mapped, wildcard field-one' do
      @list_params.search_data = {
        'wild_field_one' => :'oUP '
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [ @c_wh, @b_wh, @a_wh ] )

      @list_params.search_data = {
        'wild_field_one' => :'o!p '
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [] )
    end

    it 'finds by comma-separated list' do
      @list_params.search_data = {
        'field_two' => 'two a,something else,two c,more'
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [ @c_wh, @a_wh ] )
    end

    it 'finds by Array' do
      @list_params.search_data = {
        'field_three' => [ 'hello', :'three b', 'three c', :there ]
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [ @c_wh, @b_wh ] )
    end
  end

  # ==========================================================================

  context 'filter' do
    it 'filters without chain' do
      @list_params.filter_data = {
        'field_two' => 'two a'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@c, @b])

      @list_params.filter_data = {
        'field_three' => 'three c'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@b, @a])

      @list_params.filter_data = {
        'field_one' => [ 'group 1', 'group 2' ]
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ]
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@b, @a])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ],
        'field_three' => 'three a'
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@b])

      @list_params.filter_data = {
        'created_after' => @tn - 1.month
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@b, @a])

      @list_params.filter_data = {
        'created_on_or_before' => @tn - 1.month
      }

      finder = RSpecModelFinderTest.list( @list_params )
      expect( finder ).to eq([@c])
    end

    it 'filters with chain' do

      # Remember, the constraint is *inclusive* unlike all the
      # subsequent filters which *exclude*.

      constraint = RSpecModelFinderTest.where( :field_one => 'group 2' )

      @list_params.filter_data = {
        'field_two' => 'two a'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([@c])

      @list_params.filter_data = {
        'field_three' => 'three c'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 1', 'group 2' ]
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ]
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.filter_data = {
        'field_one' => [ 'group 2' ],
        'field_three' => 'three a'
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.filter_data = {
        'created_after' => @tn - 1.month
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([])

      @list_params.filter_data = {
        'created_on_or_before' => @tn - 1.month
      }

      finder = constraint.list( @list_params )
      expect( finder ).to eq([@c])
    end
  end

  # ==========================================================================

  # This set of copy-and-modify tests based on the helper-based search tests
  # earlier seems somewhat redundant, but should anyone accidentally decouple
  # the search/filter back-end processing and introduce some sort of error at
  # a finder-level, the tests here have a chance of catching that.

  context 'helper-based filtering' do
    it 'filters by mapped code' do
      @list_params.filter_data = {
        'mapped_code' => @code
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [ @b_wh, @a_wh ] )
    end

    it 'filters by mapped field-one' do
      @list_params.filter_data = {
        'mapped_field_one' => :'grOUp 1'
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [ @c_wh ] )
    end

    it 'filters by mapped, wildcard field-one' do
      @list_params.filter_data = {
        'wild_field_one' => :'oUP '
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [] )

      @list_params.filter_data = {
        'wild_field_one' => :'o!p '
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [ @c_wh, @b_wh, @a_wh ] )
    end


    it 'filters by comma-separated list' do
      @list_params.filter_data = {
        'field_two' => 'two a,something else,two c,more'
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [ @b_wh ] )
    end

    it 'filters by Array' do
      @list_params.filter_data = {
        'field_three' => [ 'hello', :'three b', 'three c', :there ]
      }

      finder = RSpecModelFinderTestWithHelpers.list( @list_params )
      expect( finder ).to eq( [ @a_wh ] )
    end
  end

  # ==========================================================================

  context '#list_in' do
    before :each do
      @scoped_1 = RSpecModelFinderTest.new
      @scoped_1.id   = 'id 1'
      @scoped_1.uuid = 'uuid 1'
      @scoped_1.code = 'code 1'
      @scoped_1.field_one = 'scoped 1'
      @scoped_1.created_at = @tn - 1.year
      @scoped_1.save!

      @scoped_2 = RSpecModelFinderTest.new
      @scoped_2.id   = 'id 2'
      @scoped_2.uuid = 'uuid 1'
      @scoped_2.code = 'code 2'
      @scoped_2.field_one = 'scoped 2'
      @scoped_2.save!

      @scoped_3 = RSpecModelFinderTest.new
      @scoped_3.id   = 'id 3'
      @scoped_3.uuid = 'uuid 2'
      @scoped_3.code = 'code 2'
      @scoped_3.field_one = 'scoped 3'
      @scoped_3.save!

      # Get a good-enough-for-test interaction which has a context
      # that contains a Session we can modify.

      @interaction = Hoodoo::Services::Middleware::Interaction.new( {}, nil )
      @interaction.context = Hoodoo::Services::Context.new(
        Hoodoo::Services::Session.new,
        @interaction.context.request,
        @interaction.context.response,
        @interaction
      )

      @context = @interaction.context
      @session = @interaction.context.session
    end

    it 'lists with secure scopes from the class' do
      @session.scoping = { :authorised_uuids => [ 'uuid 1' ], :authorised_code => 'code 1' }

      list = RSpecModelFinderTest.list_in( @context )
      expect( list ).to eq( [ @scoped_1 ] )

      @session.scoping.authorised_code = 'code 2'

      list = RSpecModelFinderTest.list_in( @context )
      expect( list ).to eq( [ @scoped_2 ] )

      @session.scoping.authorised_uuids = [ 'uuid 2' ]

      list = RSpecModelFinderTest.list_in( @context )
      expect( list ).to eq( [ @scoped_3 ] )

      @session.scoping.authorised_uuids = [ 'uuid 1', 'uuid 2' ]

      # OK, so these test 'with a chain' too... It's just convenient to (re-)cover
      # that aspect here.

      list = RSpecModelFinderTest.list_in( @context ).reorder( 'field_one' => 'asc' )
      expect( list ).to eq( [ @scoped_2, @scoped_3 ] )

      list = RSpecModelFinderTest.list_in( @context ).reorder( 'field_one' => 'desc' )
      expect( list ).to eq( [ @scoped_3, @scoped_2 ] )

      list = RSpecModelFinderTest.reorder( 'field_one' => 'asc' ).list_in( @context )
      expect( list ).to eq( [ @scoped_2, @scoped_3 ] )

      list = RSpecModelFinderTest.reorder( 'field_one' => 'desc' ).list_in( @context )
      expect( list ).to eq( [ @scoped_3, @scoped_2 ] )
    end

    it 'finds with secure scopes with a chain' do
      @session.scoping = { :authorised_uuids => [ 'uuid 1' ], :authorised_code => 'code 1' }

      list = RSpecModelFinderTest.where( :field_one => @scoped_1.field_one ).list_in( @context )
      expect( list ).to eq( [ @scoped_1 ] )

      list = RSpecModelFinderTest.where( :field_one => @scoped_1.field_one + '!' ).list_in( @context )
      expect( list ).to eq( [] )

      list = RSpecModelFinderTest.list_in( @context ).where( :field_one => @scoped_1.field_one )
      expect( list ).to eq( [ @scoped_1 ] )

      list = RSpecModelFinderTest.list_in( @context ).where( :field_one => @scoped_1.field_one + '!' )
      expect( list ).to eq( [] )

      @session.scoping.authorised_uuids = [ 'uuid 1', 'uuid 2' ]
      @session.scoping.authorised_code  = 'code 2'

      list = RSpecModelFinderTest.where( :field_one => [ @scoped_1.field_one, @scoped_2.field_one ] ).list_in( @context )
      expect( list ).to eq( [ @scoped_2 ] )

      list = RSpecModelFinderTest.list_in( @context ).where( :field_one => [ @scoped_1.field_one, @scoped_2.field_one ] )
      expect( list ).to eq( [ @scoped_2 ] )

      list = RSpecModelFinderTest.where( :field_one => [ @scoped_2.field_one, @scoped_3.field_one ] ).list_in( @context ).reorder( 'field_one' => 'asc' )
      expect( list ).to eq( [ @scoped_2, @scoped_3 ] )

      list = RSpecModelFinderTest.list_in( @context ).reorder( 'field_one' => 'asc' ).where( :field_one => [ @scoped_2.field_one, @scoped_3.field_one ] )
      expect( list ).to eq( [ @scoped_2, @scoped_3 ] )
    end
  end

  # ==========================================================================

  context 'deprecated' do
    it '#polymorphic_find calls #acquire' do
      expect( $stderr ).to receive( :puts ).once
      expect( RSpecModelFinderTest ).to receive( :acquire ).once.with( 21 )
      RSpecModelFinderTest.polymorphic_find( RSpecModelFinderTest, 21 )
    end

    it '#polymorphic_id_fields calls #acquire_with' do
      expect( $stderr ).to receive( :puts ).once
      expect( RSpecModelFinderTest ).to receive( :acquire_with ).once.with( :uuid, :code )
      RSpecModelFinderTest.polymorphic_id_fields( :uuid, :code )
    end

    it '#list_finder calls #list' do
      params = { :search => { :field_one => 'one' } }
      expect( $stderr ).to receive( :puts ).once
      expect( RSpecModelFinderTest ).to receive( :list ).once.with( params )
      RSpecModelFinderTest.list_finder( params )
    end

    it '#list_search_map calls #search_with' do
      params = { :foo => nil, :bar => nil }
      expect( $stderr ).to receive( :puts ).once
      expect( RSpecModelFinderTest ).to receive( :search_with ).once.with( params )
      RSpecModelFinderTest.list_search_map( params )
    end

    it '#list_filter_map calls #filter_with' do
      params = { :foo => nil, :bar => nil }
      expect( $stderr ).to receive( :puts ).once
      expect( RSpecModelFinderTest ).to receive( :filter_with ).once.with( params )
      RSpecModelFinderTest.list_filter_map( params )
    end
  end
end
