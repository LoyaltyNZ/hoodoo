require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::ManuallyDated do

  # ==========================================================================
  # Data setup
  # ==========================================================================

  BAD_DATA_FOR_VALIDATIONS = 'bad_data'

  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_manual_date_tests, :id => :string ) do | t |
        t.string :uuid, :null => false, :length => 32

        t.text :data
        t.text :unique

        t.timestamps :null => true
        t.datetime :effective_start, :null => false
        t.datetime :effective_end,   :null => false
      end

      ActiveRecord::Migration.change_column( :r_spec_model_manual_date_tests, :id, :string, :limit => 32 )

      # Documentation recommends these constraints in migrations, so ensure
      # everything works when they're present.

      ActiveRecord::Migration.add_index :r_spec_model_manual_date_tests, [        :effective_start, :effective_end ], :name => "index_rspec_mmdt_start_end"
      ActiveRecord::Migration.add_index :r_spec_model_manual_date_tests, [ :uuid, :effective_start, :effective_end ], :name => "index_rspec_mmdt_id_start_end"

      sql_date_maximum = ActiveRecord::Base.connection.quoted_date( Hoodoo::ActiveRecord::ManuallyDated::DATE_MAXIMUM )

      ActiveRecord::Migration.add_index :r_spec_model_manual_date_tests,
                                        :uuid,
                                        :unique => true,
                                        :name   => "index_rspec_mmdt_id_end",
                                        :where  => "(effective_end = '#{ sql_date_maximum }')"

      # Documentation gives something similar to this as an example of how
      # to enforce a previously-simple uniqness constraint on one column.

      ActiveRecord::Migration.add_index :r_spec_model_manual_date_tests,
                                        :unique,
                                        :unique => true,
                                        :name   => "index_rspec_mmdt_unique_ee",
                                        :where  => "(effective_end = '#{ sql_date_maximum }')"
    end

    class RSpecModelManualDateTest < ActiveRecord::Base
      include Hoodoo::ActiveRecord::ManuallyDated

      manual_dating_enabled()

      validates_each :data do | record, attribute, value |
        if value == BAD_DATA_FOR_VALIDATIONS
          record.errors.add( attribute, 'contains bad text' )
        end
      end
    end

    class RSpecModelManualDateTestOverride < ActiveRecord::Base
      include Hoodoo::ActiveRecord::ManuallyDated

      self.table_name = :r_spec_model_manual_date_tests
      manual_dating_enabled()
    end
  end

  # Create some example data for finding. The data has two different UUIDs
  # which I'll referer to as A and B. The following tables list the
  # historical and current records with their attributes. All are created
  # as rows within the main test model class's one database table.
  #
  # The data is also seeded for any other tests, so that there's a known
  # set of rows which can be examined for changes, or lack thereof.
  #
  # Historical:
  #
  # -------------------------------------------------------------------
  #  uuid | data    | created_at    | effective_end | effective_start |
  # -------------------------------------------------------------------
  #  A    | 'one'   | now - 5 hours | now - 3 hours | now - 5 hours   |
  #  B    | 'two'   | now - 4 hours | now - 2 hours | now - 4 hours   |
  #  A    | 'three' | now - 5 hours | now - 1 hour  | now - 3 hours   |
  #  B    | 'four'  | now - 4 hours | now           | now - 2 hour    |
  #
  # Current:
  #
  # -------------------------------------------------------------------
  #  uuid | data    | created_at    | effective_end | effective_start |
  # -------------------------------------------------------------------
  #  B    | 'five'  | now - 4 hours | nil           | now - 5 hours   |
  #  A    | 'six'   | now - 5 hours | nil           | now - 4 hours   |
  #
  before :each do

    @now    = Time.now.utc.round( Hoodoo::ActiveRecord::ManuallyDated::SECONDS_DECIMAL_PLACES )
    @uuid_a = Hoodoo::UUID.generate
    @uuid_b = Hoodoo::UUID.generate
    @eot    = Hoodoo::ActiveRecord::ManuallyDated::DATE_MAXIMUM

    # uuid, data, created_at, effective_end, effective_start
    [
      [ @uuid_a, 'one',   @now - 5.hours, @now - 5.hours, @now - 3.hours  ],
      [ @uuid_b, 'two',   @now - 4.hours, @now - 4.hours, @now - 2.hours  ],
      [ @uuid_a, 'three', @now - 5.hours, @now - 3.hours, @now - 1.hour   ],
      [ @uuid_b, 'four',  @now - 4.hours, @now - 2.hours, @now            ],
      [ @uuid_b, 'five',  @now - 4.hours, @now,           @eot            ],
      [ @uuid_a, 'six',   @now - 5.hours, @now - 1.hour,  @eot            ]
    ].each do | row_data |
      RSpecModelManualDateTest.new( {
        :uuid            => row_data[ 0 ],
        :data            => row_data[ 1 ],
        :created_at      => row_data[ 2 ],
        :updated_at      => row_data[ 2 ],
        :effective_start => row_data[ 3 ],
        :effective_end   => row_data[ 4 ]
      } ).save!
    end

    # This is a useful thing to have around! Just the bare minimum for the
    # API under test. At the time of writing you can actually pass a "nil"
    # context if all other attribute values are given, but that's not
    # documented and besides, we want to test a mixture of context-based
    # and explicitly specified parameters.
    #
    @context = Hoodoo::Services::Context.new( nil,
                                              Hoodoo::Services::Request.new,
                                              nil,
                                              nil )
  end

  # ==========================================================================
  # Reading tests
  # ==========================================================================

  context 'reading data' do
    context 'unscoped' do
      it 'counts all historical and current records in one database table' do
        expect( RSpecModelManualDateTest.count ).to be 6
      end

      it 'finds all historical and current records in one database table' do
        expect( RSpecModelManualDateTest.pluck( :data ) ).to match_array( [ 'one', 'two', 'three', 'four', 'five', 'six' ] )
      end
    end

    context '#manual_dating_enabled?' do
      class RSpecNotManuallyDated < Hoodoo::ActiveRecord::Base; end

      it 'says it is manually dated' do
        expect( RSpecModelManualDateTest.manual_dating_enabled? ).to eq( true )
      end

      it 'knows when something is not automatically dated' do
        expect( RSpecNotManuallyDated.manual_dating_enabled? ).to eq( false )
      end
    end

    context '#manually_dated_at' do
      it 'returns counts correctly' do
        expect( RSpecModelManualDateTest.manually_dated_at( @now - 10.hours ).count ).to be 0
        expect( RSpecModelManualDateTest.manually_dated_at( @now ).count ).to be 2
      end

      def test_expectation( time, expected_data )
        expect( RSpecModelManualDateTest.manually_dated_at( time ).pluck( :data ) ).to match_array( expected_data )
      end

      it 'returns no records before any were effective' do
        test_expectation( @now - 10.hours, [] )
      end

      it 'returns records that used to be effective starting at past time' do
        test_expectation( @now - 5.hours, [ 'one'           ] )
        test_expectation( @now - 4.hours, [ 'one', 'two'    ] )
        test_expectation( @now - 3.hours, [ 'two', 'three'  ] )
        test_expectation( @now - 2.hours, [ 'three', 'four' ] )
        test_expectation( @now - 1.hour,  [ 'four', 'six'   ] )
      end

      it 'returns records that are effective now' do
        test_expectation( @now, [ 'five', 'six' ] )
      end

      # Given the test above, if this was ignoring timezone or otherwise
      # being confused it would take "now", subtract an hour, then add it
      # back again; we'd see "five" and "six" instead of "four" and "six".
      #
      it 'converts inbound date/times to UTC' do
        local = ( @now - 1.hour ).localtime( '+01:00' )
        test_expectation( local, [ 'four', 'six' ] )
      end

      it 'works with further filtering' do
        expect( RSpecModelManualDateTest.manually_dated_at( @now ).where( :uuid => @uuid_a ).pluck( :data ) ).to eq( [ 'six' ] )
      end
    end

    context '#manually_dated' do
      it 'returns counts correctly' do
        # The contents of the Context are irrelevant aside from the fact that it
        # needs a request to store the dated_at value.
        request = Hoodoo::Services::Request.new
        context = Hoodoo::Services::Context.new( nil, request, nil, nil )

        context.request.dated_at = @now - 10.hours
        expect( RSpecModelManualDateTest.manually_dated( context ).count ).to be 0

        context.request.dated_at = @now
        expect( RSpecModelManualDateTest.manually_dated( context ).count ).to be 2
      end

      def test_expectation( time, expected_data )
        # The contents of the Context are irrelevant aside from the fact that it
        # needs a request to store the dated_at value.
        request = Hoodoo::Services::Request.new
        context = Hoodoo::Services::Context.new( nil, request, nil, nil )
        context.request.dated_at = time

        expect( RSpecModelManualDateTest.manually_dated( context ).pluck( :data ) ).to match_array( expected_data )
      end

      it 'returns no records before any were effective' do
        test_expectation( @now - 10.hours, [] )
      end

      it 'returns records that used to be effective starting at past time' do
        test_expectation( @now - 5.hours, [ 'one'           ] )
        test_expectation( @now - 4.hours, [ 'one', 'two'    ] )
        test_expectation( @now - 3.hours, [ 'two', 'three'  ] )
        test_expectation( @now - 2.hours, [ 'three', 'four' ] )
        test_expectation( @now - 1.hour,  [ 'four', 'six'   ] )
      end

      it 'returns records that are effective now' do
        test_expectation( @now, [ 'five', 'six' ] )
      end

      it 'converts inbound date/times to UTC' do
        local = ( @now - 1.hour ).localtime( '+01:00' )
        test_expectation( local, [ 'four', 'six' ] )
      end

      it 'works with further filtering' do

        # The contents of the Context are irrelevant aside from the fact that it
        # needs a request to store the dated_at value.
        request = Hoodoo::Services::Request.new
        context = Hoodoo::Services::Context.new( nil, request, nil, nil )
        context.request.dated_at = @now

        expect( RSpecModelManualDateTest.manually_dated( context ).where( :uuid => @uuid_a ).pluck( :data ) ).to eq( [ 'six' ] )
      end

      it 'works with dating last' do

        # The contents of the Context are irrelevant aside from the fact that it
        # needs a request to store the dated_at value.
        request = Hoodoo::Services::Request.new
        context = Hoodoo::Services::Context.new( nil, request, nil, nil )
        context.request.dated_at = @now

        expect( RSpecModelManualDateTest.where( :uuid => @uuid_a ).manually_dated( context ).pluck( :data ) ).to eq( [ 'six' ] )
      end
    end

    context '#manually_dated_historic' do
      it 'counts only historic entries' do
        expect( RSpecModelManualDateTest.manually_dated_historic.count ).to eq( 4 )
      end

      it 'finds only historic entries' do
        expect( RSpecModelManualDateTest.manually_dated_historic.pluck( :data ) ).to match_array( [ 'one', 'two', 'three', 'four' ] )
      end
    end

    context '#manually_dated_contemporary' do
      it 'counts only contemporary entries' do
        expect( RSpecModelManualDateTest.manually_dated_contemporary.count ).to eq( 2 )
      end

      it 'finds only contemporary entries' do
        expect( RSpecModelManualDateTest.manually_dated_contemporary.pluck( :data ) ).to match_array( [ 'five', 'six' ] )
      end
    end
  end

  # ==========================================================================
  # Hoodoo::ActiveRecord::Finder interaction
  # ==========================================================================

  context 'with Hoodoo::ActiveRecord::Finder support' do
    before :each do
      interaction = Hoodoo::Services::Middleware::Interaction.new( {}, nil )
      interaction.context = Hoodoo::Services::Context.new(
        Hoodoo::Services::Session.new,
        interaction.context.request,
        interaction.context.response,
        interaction
      )

      @context = interaction.context
    end

    context '#scoped_in' do
      it 'generates appropriate scope' do
        expect( Hoodoo::ActiveRecord::Support ).to(
          receive( :full_scope_for ).once().with(
            RSpecModelManualDateTestOverride, @context
          ).and_call_original()
        )

        sql = RSpecModelManualDateTestOverride.scoped_in( @context ).to_sql

        expect( sql ).to_not include( "UNION ALL" ) # This is only present in auto-dating, not manual dating
        expect( sql ).to     include( " AND \"r_spec_model_manual_date_tests\".\"effective_end\" > '" )
      end

      it 'generates appropriate undated scope' do
        expect( Hoodoo::ActiveRecord::Support ).to(
          receive( :add_undated_scope_to ).once().with(
            kind_of( ActiveRecord::Relation ), RSpecModelManualDateTestOverride, @context
          ).and_call_original()
        )

        sql = RSpecModelManualDateTestOverride.scoped_undated_in( @context ).to_sql

        expect( sql ).to eq( "SELECT \"r_spec_model_manual_date_tests\".* FROM \"r_spec_model_manual_date_tests\"" )
      end
    end

    context '#acquire_in' do
      context 'with contemporary' do
        it 'finds the contemporary record' do
          @context.request.dated_at            = nil
          @context.request.uri_path_components = [ @uuid_a ]

          result = RSpecModelManualDateTestOverride.acquire_in!( @context )

          expect( @context.response.halt_processing? ).to eq( false )
          expect( result.data                        ).to eq( 'six' )
        end

        it 'finds a historic record' do
          @context.request.dated_at            = @now - 4.hours
          @context.request.uri_path_components = [ @uuid_a ]

          result = RSpecModelManualDateTestOverride.acquire_in!( @context )

          expect( @context.response.halt_processing? ).to eq( false )
          expect( result.data                        ).to eq( 'one' )
        end

        it 'indicates correctly that a contemporary exists during a far-backdated lookup' do
          @context.request.dated_at            = @now - 1.year
          @context.request.uri_path_components = [ @uuid_a ]

          result = RSpecModelManualDateTestOverride.acquire_in!( @context )

          expect( @context.response.halt_processing?    ).to eq( true )
          expect( @context.response.errors.errors.count ).to eq( 2    )

          expect( @context.response.errors.errors[ 0 ][ 'code'      ] ).to eq( 'generic.not_found' )
          expect( @context.response.errors.errors[ 1 ][ 'code'      ] ).to eq( 'generic.contemporary_exists' )
          expect( @context.response.errors.errors[ 0 ][ 'reference' ] ).to eq( @uuid_a )
          expect( @context.response.errors.errors[ 1 ][ 'reference' ] ).to eq( @uuid_a )
        end
      end

      context 'with a UUID that matches no existing record' do
        it 'indicates correctly that no record exists and does not say a contemporary is present' do
          alt_uuid                             = Hoodoo::UUID.generate
          @context.request.dated_at            = @now - 5.seconds
          @context.request.uri_path_components = [ alt_uuid ]

          result = RSpecModelManualDateTestOverride.acquire_in!( @context )

          expect( @context.response.halt_processing?    ).to eq( true )
          expect( @context.response.errors.errors.count ).to eq( 1    )

          expect( @context.response.errors.errors[ 0 ][ 'code'      ] ).to eq( 'generic.not_found' )
          expect( @context.response.errors.errors[ 0 ][ 'reference' ] ).to eq( alt_uuid )
        end
      end

      context 'without contemporary' do
        before( :each ) do
          @context.request.dated_at = nil

          RSpecModelManualDateTest.manually_dated_destruction_in(
            @context,
            ident: @uuid_a
          )

          sleep( ( 0.1 ** Hoodoo::ActiveRecord::ManuallyDated::SECONDS_DECIMAL_PLACES ) * 2 )
        end

        it 'finds no contemporary record' do
          @context.request.dated_at            = nil
          @context.request.uri_path_components = [ @uuid_a ]

          result = RSpecModelManualDateTest.acquire_in!( @context )
          expect( result ).to be_nil

          expect( @context.response.halt_processing?    ).to eq( true )
          expect( @context.response.errors.errors.count ).to eq( 1    )

          expect( @context.response.errors.errors[ 0 ][ 'code'      ] ).to eq( 'generic.not_found' )
          expect( @context.response.errors.errors[ 0 ][ 'reference' ] ).to eq( @uuid_a )
        end

        it 'finds a historic record' do
          @context.request.dated_at            = @now - 4.hours
          @context.request.uri_path_components = [ @uuid_a ]

          result = RSpecModelManualDateTest.acquire_in!( @context )
          expect( result ).to_not be_nil

          expect( @context.response.halt_processing? ).to eq( false )
          expect( result.data                        ).to eq( 'one' )
        end

        it 'indicates correctly that no contemporary exists during a far-backdated lookup' do
          @context.request.dated_at            = @now - 1.year
          @context.request.uri_path_components = [ @uuid_a ]

          result = RSpecModelManualDateTest.acquire_in!( @context )
          expect( result ).to be_nil

          expect( @context.response.halt_processing?    ).to eq( true )
          expect( @context.response.errors.errors.count ).to eq( 1    )

          expect( @context.response.errors.errors[ 0 ][ 'code'      ] ).to eq( 'generic.not_found' )
          expect( @context.response.errors.errors[ 0 ][ 'reference' ] ).to eq( @uuid_a )
        end
      end
    end
  end

  # ==========================================================================
  # Writing tests
  # ==========================================================================

  context 'writing data' do
    context '#manually_dated_update_in' do
      before :each do
        @change_data_from = Hoodoo::UUID.generate()
        @change_data_to   = Hoodoo::UUID.generate()

        @record = RSpecModelManualDateTest.new( {
          :data       => @change_data_from,
          :created_at => @now,
          :updated_at => @now
        } )

        @record.save!
        sleep( ( 0.1 ** Hoodoo::ActiveRecord::ManuallyDated::SECONDS_DECIMAL_PLACES ) * 2 )

        @context.request.instance_variable_set( '@ident', @record.uuid )
        @context.request.body = { 'data' => @change_data_to }
      end

      # Call only for 'successful' update cases. Pass the result of a call to
      # #manually_dated_update_in. Expects:
      #
      # * No new 'current' items
      # * One new 'historic' item
      # * Two unscoped things can now be found by @record's UUID
      # * They should have the correct bounding dates and data.
      #
      # Remember that the very top of this file seeds in 2 contemporary and
      # 4 historical entries, so counts are relative to that baseline.
      #
      def run_expectations( result )
        expect( RSpecModelManualDateTest.manually_dated_contemporary.count ).to eq( 3 )
        expect( RSpecModelManualDateTest.manually_dated_historic.count ).to eq( 5 )
        expect( RSpecModelManualDateTest.manually_dated_contemporary.where( :uuid => @record.uuid ).count ).to eq( 1 )
        expect( RSpecModelManualDateTest.manually_dated_historic.where( :uuid => @record.uuid ).count ).to eq( 1 )

        # Current record is now at 'no'/nil time - i.e. actually Time.now. The
        # time frozen into "@now" at the top of this file is by this point the
        # historic time of the old record.

        historic = RSpecModelManualDateTest.manually_dated_at( @now ).find_by_uuid( @record.uuid )
        current  = RSpecModelManualDateTest.manually_dated_at().find_by_uuid( @record.uuid )

        expect( result.uuid ).to eq( current.uuid )

        expect( historic.data ).to eq( @change_data_from )
        expect( current.data  ).to eq( @change_data_to   )

        expect( historic.effective_end ).to eq( current.effective_start )
        expect( historic.effective_end ).to eq( current.updated_at      )
        expect( current.effective_end  ).to eq( @eot                    )
      end

      it 'via context alone' do
        result = RSpecModelManualDateTest.manually_dated_update_in(
          @context
        )

        run_expectations( result )
      end

      # Generate a random => invalid UUID in the request data to prove that
      # the valid one given in the input parameter is used as an override.
      #
      it 'specifying "ident"' do
        @context.request.instance_variable_set( '@ident', Hoodoo::UUID.generate() )

        result = RSpecModelManualDateTest.manually_dated_update_in(
          @context,
          ident: @record.uuid
        )

        run_expectations( result )
      end

      # Generate a random => invalid payload in the request data to prove that
      # the valid one given in the input parameter is used as an override.
      #
      it 'specifying "attributes"' do
        @context.request.body = { Hoodoo::UUID.generate() => 42 }

        result = RSpecModelManualDateTest.manually_dated_update_in(
          @context,
          attributes: { 'data' => @change_data_to }
        )

        run_expectations( result )
      end

      # If 'ident' and 'attributes' are given, 'context' can be "nil".
      #
      it 'specifying "ident" and "attributes" with nil "context"' do
        @context.request.instance_variable_set( '@ident', Hoodoo::UUID.generate() )

        result = RSpecModelManualDateTest.manually_dated_update_in(
          nil,
          ident: @record.uuid,
          attributes: { 'data' => @change_data_to }
        )

        run_expectations( result )
      end

      it 'uses a given scope' do

        # We expect the custom scope to be customised to find an
        # acquisition scope for locking, if it's being used OK.
        # This is fragile; depends heavily on implementation.

        custom_scope = RSpecModelManualDateTest.where( :data => [ 'one', 'two', 'three' ] + [ @change_data_from ] )
        expect( custom_scope ).to receive( :acquisition_scope ).and_call_original

        result = RSpecModelManualDateTest.manually_dated_update_in(
          @context,
          scope: custom_scope
        )

        run_expectations( result )
      end

      context 'handles not-found' do
        it 'because of a bad identifier' do
          result = RSpecModelManualDateTest.manually_dated_update_in(
            @context,
            ident: Hoodoo::UUID.generate() # Random => invalid
          )

          expect( result ).to be_nil
        end

        it 'because of a scope' do
          result = RSpecModelManualDateTest.manually_dated_update_in(
            @context,
            scope: RSpecModelManualDateTest.where( :data => [ Hoodoo::UUID.generate() ] ) # Random => invalid
          )

          expect( result ).to be_nil
        end
      end

      context 'exceptions' do
        def expect_correct_rollback( &block )
          starting_original = RSpecModelManualDateTest.manually_dated_contemporary.acquire_in( @context )
          expect( starting_original ).to_not be_nil # Self-check this test

          yield( block )

          ending_original = RSpecModelManualDateTest.manually_dated_contemporary.acquire_in( @context )

          expect( ending_original ).to_not be_nil
          expect( starting_original.attributes ).to eq( ending_original.attributes )
        end

        it 'handles validation errors and does not change the contemporary record' do
          expect_correct_rollback do
            result = nil

            expect {
              result = RSpecModelManualDateTest.manually_dated_update_in(
                @context,
                attributes: { 'data' => BAD_DATA_FOR_VALIDATIONS }
              )
            }.to_not change( RSpecModelManualDateTest, :count )

            expect( result ).to_not be_nil
            expect( result.persisted? ).to eq( false )
            expect( result.errors.messages ).to eq( { :data => [ 'contains bad text' ] } )
          end
        end

        it 'correctly rolls back in the face of unexpected exceptions' do
          expect_correct_rollback do
            expect_any_instance_of( RSpecModelManualDateTest ).to receive( :save ) {
              raise 'stop'
            }

            expect {
              expect {
                RSpecModelManualDateTest.manually_dated_update_in(
                  @context,
                  attributes: { 'data' => Hoodoo::UUID.generate() }
                )
              }.to raise_exception( RuntimeError, 'stop' )
            }.to_not change( RSpecModelManualDateTest, :count )
          end
        end

        it 'retries after one deadlock' do
          raised = false

          allow_any_instance_of( RSpecModelManualDateTest ).to receive( :update_column ) do | instance, name, value |
            if raised == false
              raised = true
              raise ::ActiveRecord::StatementInvalid.new( 'MOCK DEADLOCK EXCEPTION' )
            else
              instance.update_attribute( name, value )
            end
          end

          result = nil

          expect {
            result = RSpecModelManualDateTest.manually_dated_update_in(
              @context,
              attributes: { 'data' => Hoodoo::UUID.generate() }
            )
          }.to change( RSpecModelManualDateTest, :count ).by( 1 )

          expect( result ).to_not be_nil
          expect( result.errors.messages ).to be_empty
          expect( result.persisted? ).to eq( true )
        end

        it 'gives up after two deadlocks' do
          allow_any_instance_of( RSpecModelManualDateTest ).to receive( :update_column ) do | instance, name, value |
            raise ::ActiveRecord::StatementInvalid.new( 'MOCK DEADLOCK EXCEPTION' )
          end

          expect_correct_rollback do
            expect {
              result = RSpecModelManualDateTest.manually_dated_update_in(
                @context,
                attributes: { 'data' => Hoodoo::UUID.generate() }
              )
            }.to raise_exception( ::ActiveRecord::StatementInvalid )
          end
        end
      end
    end

    context '#manually_dated_destruction_in' do
      before :each do
        @data   = Hoodoo::UUID.generate()
        @record = RSpecModelManualDateTest.new( {
          :data       => @data,
          :created_at => @now,
          :updated_at => @now
        } )

        @record.save!
        sleep( ( 0.1 ** Hoodoo::ActiveRecord::ManuallyDated::SECONDS_DECIMAL_PLACES ) * 2 )

        @old_updated_at = @record.updated_at

        @context.request.instance_variable_set( '@ident', @record.uuid )
      end

      # Call only for 'successful' delete cases. Pass the result of a call to
      # #manually_dated_update_in. Expects:
      #
      # * One fewer 'current' items
      # * One more 'historic' item
      # * One unscoped thing can now be found by @record's UUID
      # * It should have the correct bounding dates and data.
      #
      # Remember that the very top of this file seeds in 2 contemporary and
      # 4 historical entries, so counts are relative to that baseline.
      #
      def run_expectations( result )
        expect( RSpecModelManualDateTest.manually_dated_contemporary.count ).to eq( 2 )
        expect( RSpecModelManualDateTest.manually_dated_historic.count ).to eq( 5 )
        expect( RSpecModelManualDateTest.manually_dated_contemporary.where( :uuid => @record.uuid ).count ).to eq( 0 )
        expect( RSpecModelManualDateTest.manually_dated_historic.where( :uuid => @record.uuid ).count ).to eq( 1 )

        # Current record is now at 'no'/nil time - i.e. actually Time.now. The
        # time frozen into "@now" at the top of this file is by this point the
        # historic time of the old record.

        historic = RSpecModelManualDateTest.manually_dated_at( @now ).find_by_uuid( @record.uuid )

        expect( historic.data ).to eq( @data )

        expect( historic.effective_end ).to_not eq( @eot )
        expect( historic.updated_at ).to eq( @old_updated_at )
      end

      it 'via context alone' do
        result = RSpecModelManualDateTest.manually_dated_destruction_in(
          @context
        )

        run_expectations( result )
      end

      # Generate a random => invalid UUID in the request data to prove that
      # the valid one given in the input parameter is used as an override.
      #
      it 'specifying "ident"' do
        @context.request.instance_variable_set( '@ident', Hoodoo::UUID.generate() )

        result = RSpecModelManualDateTest.manually_dated_destruction_in(
          @context,
          ident: @record.uuid
        )

        run_expectations( result )
      end

      # If 'ident' is given, 'context' can be "nil".
      #
      it 'specifying "ident" with nil "context"' do
        @context.request.instance_variable_set( '@ident', Hoodoo::UUID.generate() )

        result = RSpecModelManualDateTest.manually_dated_destruction_in(
          nil,
          ident: @record.uuid
        )

        run_expectations( result )
      end

      it 'uses a given scope' do

        # We expect the custom scope to be customised to find an
        # contemporary dated record for locking, if it's being used
        # OK. This is fragile; depends heavily on implementation.

        custom_scope = RSpecModelManualDateTest.where( :data => [ 'one', 'two', 'three' ] + [ @data ] )
        expect( custom_scope ).to receive( :manually_dated_contemporary ).and_call_original

        result = RSpecModelManualDateTest.manually_dated_destruction_in(
          @context,
          scope: custom_scope
        )

        run_expectations( result )
      end

      context 'handles not-found' do
        it 'because of a bad identifier' do
          result = RSpecModelManualDateTest.manually_dated_destruction_in(
            @context,
            ident: Hoodoo::UUID.generate() # Random => invalid
          )

          expect( result ).to be_nil
        end

        it 'because of a scope' do
          result = RSpecModelManualDateTest.manually_dated_destruction_in(
            @context,
            scope: RSpecModelManualDateTest.where( :data => [ Hoodoo::UUID.generate() ] ) # Random => invalid
          )

          expect( result ).to be_nil
        end
      end
    end

    context 'update then delete' do
      it 'works' do
        record = RSpecModelManualDateTest.new( {
          :data       => Hoodoo::UUID.generate(),
          :created_at => @now,
          :updated_at => @now
        } )

        record.save!

        3.times do
          result = RSpecModelManualDateTest.manually_dated_update_in(
            @context,
            ident: record.uuid,
            attributes: { 'data' => Hoodoo::UUID.generate() }
          )

          expect( result ).to_not be_nil
          expect( result.errors.messages ).to be_empty
          expect( result.persisted? ).to eq( true )
        end

        result = RSpecModelManualDateTest.manually_dated_destruction_in(
          @context,
          ident: record.uuid
        )

        expect( result ).to_not be_nil

        # We start with one current record, but it gets updated three times,
        # creating three history entries. Then it gets deleted, creating
        # another history entry and leaving no current ones.
        #
        # Remember that the very top of this file seeds in 2 contemporary and
        # 4 historical entries, so counts are relative to that baseline.

        expect( RSpecModelManualDateTest.manually_dated_contemporary.count ).to eq( 2 )
        expect( RSpecModelManualDateTest.manually_dated_historic.count ).to eq( 8 )
        expect( RSpecModelManualDateTest.manually_dated_contemporary.where( :uuid => record.uuid ).count ).to eq( 0 )
        expect( RSpecModelManualDateTest.manually_dated_historic.where( :uuid => record.uuid ).count ).to eq( 4 )
      end
    end
  end

  context 'inbound date-time rounding' do
    it 'rounds ActiveRecord-assigned timestamps' do
      record = RSpecModelManualDateTest.new( {
        :data => Hoodoo::UUID.generate()
      } )

      record.save!

      %i{ created_at updated_at effective_start effective_end }.each do | attr |
        value = record.send( attr )
        expect( value.utc.round( Hoodoo::ActiveRecord::ManuallyDated::SECONDS_DECIMAL_PLACES ) ).to eq( value )
      end
    end

    it 'rounds explicitly assigned timestamps' do
      record = RSpecModelManualDateTest.new( {
        :data => Hoodoo::UUID.generate(),
        :created_at      => Time.now - 2.seconds,
        :updated_at      => Time.now - 1.seconds,
        :effective_start => Time.now - 2.seconds,
        :effective_end   => Time.now - 1.seconds
      } )

      record.save!

      %i{ created_at updated_at effective_start effective_end }.each do | attr |
        value = record.send( attr )
        expect( value.utc.round( Hoodoo::ActiveRecord::ManuallyDated::SECONDS_DECIMAL_PLACES ) ).to eq( value )
      end
    end
  end

  # Rapid updates within configured date resolution might not be resolvable
  # as individual history items via API, but they should still exist and
  # things like uuid/start/end uniqueness constraint columns ought to still
  # function without false positives.
  #
  context 'rapid updates' do
    it 'does not hit uniqueness constraint violations during very rapid update attempts' do
      overall_before      = RSpecModelManualDateTest.count
      historic_before     = RSpecModelManualDateTest.manually_dated_historic.count
      contemporary_before = RSpecModelManualDateTest.manually_dated_contemporary.count
      update_count        = 20

      record = RSpecModelManualDateTest.new( {
        :data       => Hoodoo::UUID.generate(),
        :created_at => Time.now - 1.year
      } )

      record.save!

      1.upto( update_count ) do
        result = RSpecModelManualDateTest.manually_dated_update_in(
          @context,
          ident: record.uuid,
          attributes: { 'data' => Hoodoo::UUID.generate() }
        )

        expect( result ).to_not be_nil
        expect( result.errors.messages ).to be_empty
        expect( result.persisted? ).to eq( true )
      end

      overall_after      = RSpecModelManualDateTest.count
      historic_after     = RSpecModelManualDateTest.manually_dated_historic.count
      contemporary_after = RSpecModelManualDateTest.manually_dated_contemporary.count

      expect( overall_after      - overall_before      ).to eq( update_count + 1 )
      expect( historic_after     - historic_before     ).to eq( update_count     )
      expect( contemporary_after - contemporary_before ).to eq( 1                )

      expect( RSpecModelManualDateTest.where( :uuid => record.uuid ).count ).to eq( update_count + 1 )
      expect( RSpecModelManualDateTest.manually_dated_historic.where( :uuid => record.uuid ).count ).to eq( update_count )
      expect( RSpecModelManualDateTest.manually_dated_contemporary.where( :uuid => record.uuid ).count ).to eq( 1 )
    end
  end

  context 'uniqueness' do
    before :all do
      @unique = Hoodoo::UUID.generate()
    end

    it 'allows duplications within same resource instance history' do

      # First generate a unique record

      record = RSpecModelManualDateTest.new( {
        :data       => Hoodoo::UUID.generate(),
        :unique     => @unique,
        :created_at => Time.now - 1.year
      } )

      record.save!

      # Now update it

      result = RSpecModelManualDateTest.manually_dated_update_in(
        @context,
        ident: record.uuid,
        attributes: { 'data' => Hoodoo::UUID.generate() }
      )

      # We should end up with two records; one historic and one contemporary

      expect( result ).to_not be_nil
      expect( result.errors.messages ).to be_empty
      expect( result.persisted? ).to eq( true )
      expect( RSpecModelManualDateTest.where( :unique => @unique ).count ).to eq( 2 )
      expect( RSpecModelManualDateTest.manually_dated_historic.where( :unique => @unique ).count ).to eq( 1 )
      expect( RSpecModelManualDateTest.manually_dated_contemporary.where( :unique => @unique ).count ).to eq( 1 )

    end

    it 'prohibits duplicates across different resource instances' do

      # First generate a unique record

      record = RSpecModelManualDateTest.new( {
        :data       => Hoodoo::UUID.generate(),
        :unique     => @unique,
        :created_at => Time.now - 1.year
      } )

      record.save!

      # Now make another one; this should be prohibited.

      another_record = RSpecModelManualDateTest.new( {
        :data   => Hoodoo::UUID.generate(),
        :unique => @unique
      } )

      expect {
        another_record.save!
      }.to raise_error( ::ActiveRecord::RecordNotUnique )

      expect( RSpecModelManualDateTest.where( :unique => @unique ).count ).to eq( 1 )

    end

    it 'prohibits duplications when there is resource history and a contemporary record' do

      # A fair bit of cut-and-paste here.. First generate, then update
      # one record.

      record = RSpecModelManualDateTest.new( {
        :data       => Hoodoo::UUID.generate(),
        :unique     => @unique,
        :created_at => Time.now - 1.year
      } )

      record.save!

      result = RSpecModelManualDateTest.manually_dated_update_in(
        @context,
        ident: record.uuid,
        attributes: { 'data' => Hoodoo::UUID.generate() }
      )

      # We should end up with two records; one historic and one contemporary

      expect( result ).to_not be_nil
      expect( result.errors.messages ).to be_empty
      expect( result.persisted? ).to eq( true )
      expect( RSpecModelManualDateTest.where( :unique => @unique ).count ).to eq( 2 )
      expect( RSpecModelManualDateTest.manually_dated_historic.where( :unique => @unique ).count ).to eq( 1 )
      expect( RSpecModelManualDateTest.manually_dated_contemporary.where( :unique => @unique ).count ).to eq( 1 )

      # We should be unable to make a new instance that duplicates the unique
      # value.

      another_record = RSpecModelManualDateTest.new( {
        :data   => Hoodoo::UUID.generate(),
        :unique => @unique
      } )

      expect {
        another_record.save!
      }.to raise_error( ::ActiveRecord::RecordNotUnique )

      expect( RSpecModelManualDateTest.where( :unique => @unique ).count ).to eq( 2 )

    end

    it 'allows duplications when an old resource instance has been deleted' do

      # First generate a unique record

      record = RSpecModelManualDateTest.new( {
        :data       => Hoodoo::UUID.generate(),
        :unique     => @unique,
        :created_at => Time.now - 1.year
      } )

      record.save!

      # Now delete it

      result = RSpecModelManualDateTest.manually_dated_destruction_in(
        @context,
        ident: record.uuid
      )

      # We should end up with one historic record

      expect( result ).to_not be_nil
      expect( RSpecModelManualDateTest.where( :unique => @unique ).count ).to eq( 1 )
      expect( RSpecModelManualDateTest.manually_dated_historic.where( :unique => @unique ).count ).to eq( 1 )
      expect( RSpecModelManualDateTest.manually_dated_contemporary.where( :unique => @unique ).count ).to eq( 0 )

      # For safety/test reliability, sleep to make sure we are beyond the
      # limits of configured date accuracy.

      sleep( ( 0.1 ** Hoodoo::ActiveRecord::ManuallyDated::SECONDS_DECIMAL_PLACES ) * 2 )

      # We should be able to make a new instance with the unique value now

      another_record = RSpecModelManualDateTest.new( {
        :data   => Hoodoo::UUID.generate(),
        :unique => @unique
      } )

      another_record.save!

      # We should end up with two records; one old UUID historic and one new
      # UUID contemporary

      expect( another_record ).to_not be_nil
      expect( another_record.errors.messages ).to be_empty
      expect( another_record.persisted? ).to eq( true )
      expect( RSpecModelManualDateTest.where( :unique => @unique ).count ).to eq( 2 )
      expect( RSpecModelManualDateTest.manually_dated_historic.where( :unique => @unique ).count ).to eq( 1 )
      expect( RSpecModelManualDateTest.manually_dated_contemporary.where( :unique => @unique ).count ).to eq( 1 )
      expect( RSpecModelManualDateTest.manually_dated_historic.where( :unique => @unique, :uuid => record.uuid ).count ).to eq( 1 )
      expect( RSpecModelManualDateTest.manually_dated_contemporary.where( :unique => @unique, :uuid => another_record.uuid ).count ).to eq( 1 )
    end
  end

  context 'concurrent' do
    before :all do
      DatabaseCleaner.strategy = :truncation
    end

    after :all do
      DatabaseCleaner.strategy = DATABASE_CLEANER_STRATEGY # spec_helper.rb
    end

    before :each do
      @uuids   = []
      @results = {}
      @mutex   = Mutex.new

      # From a pool of UUIDs, create a bunch of records.

      50.times { @uuids << Hoodoo::UUID.generate }
      @uuids.uniq! # Just in case I should've entered the lottery this week

      @uuids.each do | uuid |
        RSpecModelManualDateTest.new( {
          :uuid => uuid,
          :data => '0'
        } ).save!
      end
    end

    def add_result( uuid, result )
      @mutex.synchronize do
        @results[ uuid ] ||= []
        @results[ uuid ] << result
      end
    end

    # - Start threads that update the records with values, one update per thread
    # - Check that the combined unscoped set has all integers and nothing more
    # - Check there is only one contemporary entry per UUID and num-ints-minus-one
    #   history entries
    #
    it 'updates work' do
      values  = ( '1'..'5' ).to_a
      threads = []

      # The loop below creates a Thread for each 'value', and each Thread
      # consumes a db connection, so we have to check that the pool is big enough
      # to ensure that each thread gets a connection.
      #
      # A better solution would be to temporarily create a connection pool with
      # more connections in it, but attempts to do that broke other parts of this
      # spec :-(
      #
      expect( ActiveRecord::Base.connection_pool.size ).to be >= values.size
      # Reclaim old, unused connections
      ActiveRecord::Base.connection_pool.reap()

      @uuids.each do | uuid |
        values.each do | value |
          threads << Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              sleep 0.001 # Force Thread scheduler to run

              result = RSpecModelManualDateTest.manually_dated_update_in(
                @context,
                ident: uuid,
                attributes: { 'data' => value }
              )

              add_result( uuid, result )
            end
          end
        end
        threads.each { | thread | thread.join() }
      end


      @uuids.each do | uuid |
        contemporary = RSpecModelManualDateTest.manually_dated_contemporary.where( :uuid => uuid ).to_a
        historic     = RSpecModelManualDateTest.manually_dated_historic.where( :uuid => uuid ).to_a

        expect( contemporary.count ).to eq( 1 )
        expect( historic.count     ).to eq( values.count )

        # Across all records, the starting data value of "0" plus any
        # new items in "values" should be present exactly once.

        combined = ( contemporary + historic ).map( & :data )
        expect( combined ).to match_array( [ '0' ] + values )

        # All results should be persisted model instances which, once
        # reloaded, only have one contemporary entry and the rest historic.
        # This double-checks the database query tests a few lines above.

        results = @results[ uuid ]

        results.each do | result |
          expect( result ).to be_a( RSpecModelManualDateTest )
          expect( result.errors.messages ).to be_empty
          expect( result.persisted? ).to eq( true )

          result.reload
        end

        dates  = results.map( & :effective_end )
        eots   = dates.select() { | date | date == @eot }
        others = dates.reject() { | date | date == @eot }

        # "- 1" because the results Hash only contains results of the
        # *updates* we did, not the original starting record.

        expect(   eots.count ).to eq( 1 )
        expect( others.count ).to eq( values.count - 1 )
      end
    end

    # - Start several threads that delete the same records
    # - Push results into the results hash
    # - Check that only one thread succeeded, rest of them got 'nil' (not found),
    #     only one history entry per UUID, no contemporary entry per UUID.
    #
    it 'deletions work' do
      threads  = []
      attempts = 10

      @uuids.each do | uuid |
        attempts.times do
          threads << Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              result = RSpecModelManualDateTest.manually_dated_destruction_in(
                @context,
                ident: uuid
              )

              add_result( uuid, result )
            end
          end
        end
      end

      threads.each { | thread | thread.join() }

      @uuids.each do | uuid |
        contemporary = RSpecModelManualDateTest.manually_dated_contemporary.where( :uuid => uuid ).to_a
        historic     = RSpecModelManualDateTest.manually_dated_historic.where( :uuid => uuid ).to_a

        expect( contemporary.count ).to eq( 0 )
        expect( historic.count     ).to eq( 1 )

        # We expect all results to contain one success and lots of failures.

        results   = @results[ uuid ]
        failures  = results.select() { | result | result.nil? }
        successes = results.reject() { | result | result.nil? }

        expect( failures.count  ).to eq( attempts - 1 )
        expect( successes.count ).to eq( 1 )

        success = successes.first
        success.reload

        expect( success ).to be_a( RSpecModelManualDateTest )
        expect( success.errors.messages ).to be_empty
        expect( success.persisted? ).to eq( true )
        expect( success.effective_end ).to_not eq( @eot )
      end
    end

  end
end
