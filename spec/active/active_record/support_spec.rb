require 'spec_helper'
require 'active/active_record/error_mapping_shared_context'

describe Hoodoo::ActiveRecord::Support do
  context '#framework_search_and_filter_data' do
    it 'returns the expected number of keys' do
      hash = described_class.framework_search_and_filter_data()
      expect( hash.keys.count ).to eq( Hoodoo::Services::Middleware::FRAMEWORK_QUERY_DATA.keys.count )
    end

    it 'complains if there is a mismatch' do
      middleware = Hoodoo::Services::Middleware
      old_value  = middleware.const_get( 'FRAMEWORK_QUERY_DATA' )

      middleware.send( :remove_const, 'FRAMEWORK_QUERY_DATA' )
      middleware.const_set( 'FRAMEWORK_QUERY_DATA', old_value.merge( { Hoodoo::UUID.generate() => 1 } ) )

      expect {
        described_class.framework_search_and_filter_data()
      }.to raise_error( RuntimeError, 'Hoodoo::ActiveRecord::Support#framework_search_and_filter_data: Mismatch between internal mapping and Hoodoo::Services::Middleware::FRAMEWORK_QUERY_DATA' )

      middleware.send( :remove_const, 'FRAMEWORK_QUERY_DATA' )
      middleware.const_set( 'FRAMEWORK_QUERY_DATA', old_value )
    end
  end

  context '#self.process_to_map' do
    it 'processes as expected' do
      proc1 = Proc.new { puts "hello" }
      proc2 = Proc.new { puts "world" }

      hash = {
        :foo => nil,
        'bar' => nil,
        :baz => proc1,
        'boo' => proc2
      }

      map = described_class.process_to_map( hash )

      # Ensure all keys become strings. The 'nil' values should become matcher
      # Procs per Hoodoo::ActiveRecord::Finder::SearchHelper.cs_match, however
      # you can't compare Proc instances; so instead run those Procs and check
      # the expected results.
      #
      # Since a created Proc is supposed to encode the attribute name into the
      # Proc via the key in the input hash, any run-time specification of an
      # attribute name ought to be ignored if the mapping method is working as
      # expected.

      expect( map[ 'foo' ] ).to be_a( Proc )
      expect( map[ 'foo' ].call( 'ignored', 'val1' ) ).to eq( [ 'foo = ? AND foo IS NOT NULL', 'val1' ] )

      expect( map[ 'bar' ] ).to be_a( Proc )
      expect( map[ 'bar' ].call( 'ignored', 'val2' ) ).to eq( [ 'bar = ? AND bar IS NOT NULL', 'val2' ] )

      expect( map[ 'baz' ] ).to eq( proc1 )

      expect( map[ 'boo' ] ).to eq( proc2 )
    end
  end

  context '#full_scope_for and #add_undated_scope_to' do

    # Here we not only test the full scope generator with all mixins included,
    # and test them all in a *deactivated* state, we also check that inheritance
    # can then override that condition without disturbing the base class to
    # ensure that "class attribute" style code, rather than "@@" class variable
    # style code, is being maintained in the mixins. Then check the reverse -
    # make sure things in the base class do get inherited by subclasses.

    before :all do
      @thtname1 = 'r_spec_full_scope_for_test_foo_history'
      @thtname2 = 'r_spec_full_scope_for_test_with_directives_foo_history'

      spec_helper_silence_stdout() do
        ActiveRecord::Migration.create_table( :r_spec_full_scope_for_test_bases ) do | t |
          t.timestamps :null => true
        end

        ActiveRecord::Migration.create_table( :r_spec_full_scope_for_test_subclasses ) do | t |
          t.string :foo
          t.timestamps :null => true
        end

        ActiveRecord::Migration.create_table( @thtname1 ) do | t |
          t.string :foo
          t.timestamps :null => true
        end

        ActiveRecord::Migration.create_table( :rspec_full_scope_for_test_base_with_directives_custom ) do | t |
          t.string :bar
          t.timestamps :null => true
        end

        ActiveRecord::Migration.create_table( @thtname2 ) do | t |
          t.string :bar
          t.timestamps :null => true
        end

        ActiveRecord::Migration.create_table( :r_spec_full_scope_for_manually_dateds ) do | t |
          t.string :baz
          t.string :uuid, :length => 32
          t.datetime :effective_start
          t.datetime :effective_end
          t.timestamps :null => true
        end
      end

      # Note inheritance from plain ActiveRecord::Base, important for
      # additional coverage. Module inclusions are thus done manually.

      class RSpecFullScopeForTestBase < ActiveRecord::Base
        include Hoodoo::ActiveRecord::Secure
        include Hoodoo::ActiveRecord::Dated
        include Hoodoo::ActiveRecord::Translated
      end

      class RSpecFullScopeForTestSubclass < RSpecFullScopeForTestBase
        TEST_HISTORY_TABLE_NAME = 'r_spec_full_scope_for_test_foo_history'

        self.table_name = :r_spec_full_scope_for_test_subclasses
        secure_with( :foo => :foo )
        dating_enabled( :history_table_name => TEST_HISTORY_TABLE_NAME )
      end

      # Note inheritance from Hoodoo::ActiveRecord::Base, important for
      # additional coverage. Module inclusions are automatic.

      class RSpecFullScopeForTestBaseWithDirectives < Hoodoo::ActiveRecord::Base
        TEST_HISTORY_TABLE_NAME = 'r_spec_full_scope_for_test_with_directives_foo_history'

        self.table_name = :rspec_full_scope_for_test_base_with_directives_custom
        secure_with( :bar => :foo )
        dating_enabled( :history_table_name => TEST_HISTORY_TABLE_NAME )
      end

      class RSpecFullScopeForTestBaseSubclassWithoutOverrides < RSpecFullScopeForTestBaseWithDirectives
        # No overrides at all
      end

      # Manual and automatic effective dating can live in the same mixin
      # collection but can't both be enabled at the same time, so do this
      # in a special test class with a database table that meets the
      # related requirements.
      #
      class RSpecFullScopeForManuallyDated < Hoodoo::ActiveRecord::Base
        secure_with( :baz => :baz )
        manual_dating_enabled()
      end
    end

    before :each do

      # Get a good-enough-for-test interaction and context.

      @interaction = Hoodoo::Services::Middleware::Interaction.new( {}, nil )
      @interaction.context = Hoodoo::Services::Context.new(
        Hoodoo::Services::Session.new,
        @interaction.context.request,
        @interaction.context.response,
        @interaction
      )

      @context = @interaction.context
      @session = @interaction.context.session

      # Now set up the data inside that context so that the tests generate
      # predictable SQL output.

      @test_time_value = DateTime.now
      @context.request.dated_at = @test_time_value

      @test_scoping_value = 23
      @session.scoping = OpenStruct.new
      @session.scoping.foo = [ @test_scoping_value ]
    end

    context '(with subclass overriding base class)' do
      it 'prerequisites' do
        expect( RSpecFullScopeForTestBase.all().to_sql() ).to_not eq( RSpecFullScopeForTestSubclass.all().to_sql() )
      end

      it 'gets "all" scope in the base class' do

        # There are no module activations in the base class so we expect to
        # get the "all" context, the subclass's activations having not made
        # any difference to it.

        auto_scope   = described_class.full_scope_for( RSpecFullScopeForTestBase, @context ).to_sql()
        manual_scope = RSpecFullScopeForTestBase.all().to_sql()

        expect( auto_scope ).to eq( manual_scope )
      end

      context 'gets customised scope in the subclass:' do

        # These first tests just make sure that the individual modules
        # are generating expected scoping data, so that we aren't accidentally
        # comparing malfunctioning scope inclusions against each other (e.g.
        # empty strings).

        it 'dated' do
          manual_scope = RSpecFullScopeForTestSubclass.dated( @context ).to_sql()

          expect( manual_scope ).to include( "FROM #{ @thtname1 }" )
          expect( manual_scope ).to include( "\"effective_end\" > '#{ RSpecFullScopeForTestSubclass.connection.quoted_date( @test_time_value ) }'" )
        end

        it 'secure' do
          manual_scope = RSpecFullScopeForTestSubclass.secure( @context ).to_sql()

          expect( manual_scope ).to include( "\"r_spec_full_scope_for_test_subclasses\".\"foo\" = '#{ @test_scoping_value }'" )
        end

        pending 'translated' # Scope verification for '#translated'

        # Finally, we actually check full_scope_for / add_undated_scope_to;
        # activations are in the subclass so we drive the non-context versions
        # directly to verify that the context chain worked.

        it 'everything' do
          auto_scope   = described_class.full_scope_for( RSpecFullScopeForTestSubclass, @context ).to_sql()
          manual_scope = RSpecFullScopeForTestSubclass.secure( @context ).dated( @context ).translated( @context ).to_sql()

          expect( auto_scope ).to eq( manual_scope )
        end

        it 'undated' do
          auto_scope = described_class.add_undated_scope_to(
            RSpecFullScopeForTestSubclass.all(),
            RSpecFullScopeForTestSubclass,
            @context
          ).to_sql()

          manual_scope = RSpecFullScopeForTestSubclass.secure( @context ).translated( @context ).to_sql()

          expect( auto_scope ).to eq( manual_scope )
        end
      end
    end

    context '(with base class definitions used by subclass)' do
      it 'prerequisites' do
        expect( RSpecFullScopeForTestBaseWithDirectives.all().to_sql ).to eq( RSpecFullScopeForTestBaseSubclassWithoutOverrides.all().to_sql() )
      end

      # As above - some tests to check individual scopes work (paranoia), then
      # the actual #full_scope_for test which puts it all together.

      it 'dated' do
        manual_scope = RSpecFullScopeForTestBaseSubclassWithoutOverrides.dated( @context ).to_sql()

        expect( manual_scope ).to include( "FROM #{ @thtname2 }" )
        expect( manual_scope ).to include( "\"effective_end\" > '#{ RSpecFullScopeForTestBaseSubclassWithoutOverrides.connection.quoted_date( @test_time_value ) }'" )
      end

      it 'secure' do
        manual_scope = RSpecFullScopeForTestBaseSubclassWithoutOverrides.secure( @context ).to_sql()

        expect( manual_scope ).to include( "\"rspec_full_scope_for_test_base_with_directives_custom\".\"bar\" = '#{ @test_scoping_value }'" )
      end

      pending 'translated' # Scope verification for '#translated'

      it 'yields the same SQL' do
        auto_scope   = described_class.full_scope_for( RSpecFullScopeForTestBaseSubclassWithoutOverrides, @context ).to_sql()
        manual_scope = RSpecFullScopeForTestBaseSubclassWithoutOverrides.secure( @context ).dated( @context ).translated( @context ).to_sql()

        expect( auto_scope ).to eq( manual_scope )
      end
    end

    context '(with manual dating enabled)' do
      before :each do
        @session.scoping.baz = [ @test_scoping_value ]
      end

      context 'gets customised scope:' do
        it 'manually dated' do
          manual_scope = RSpecFullScopeForManuallyDated.manually_dated( @context ).to_sql()

          expect( manual_scope ).to include( 'FROM "r_spec_full_scope_for_manually_dateds"' )
          expect( manual_scope ).to include( "\"effective_end\" > '#{ RSpecFullScopeForTestSubclass.connection.quoted_date( @test_time_value.to_time.round( Hoodoo::ActiveRecord::ManuallyDated::SECONDS_DECIMAL_PLACES ) ) }'" )
        end

        it 'secure' do
          manual_scope = RSpecFullScopeForManuallyDated.secure( @context ).to_sql()

          expect( manual_scope ).to include( "\"r_spec_full_scope_for_manually_dateds\".\"baz\" = '#{ @test_scoping_value }'" )
        end

        pending 'translated' # Scope verification for '#translated'

        it 'everything' do
          auto_scope   = described_class.full_scope_for( RSpecFullScopeForManuallyDated, @context ).to_sql()
          manual_scope = RSpecFullScopeForManuallyDated.manually_dated( @context ).secure( @context ).translated( @context ).to_sql()

          expect( auto_scope ).to eq( manual_scope )
        end

        it 'undated' do
          auto_scope = described_class.add_undated_scope_to(
            RSpecFullScopeForManuallyDated.all(),
            RSpecFullScopeForManuallyDated,
            @context
          ).to_sql()

          manual_scope = RSpecFullScopeForManuallyDated.secure( @context ).translated( @context ).to_sql()

          expect( auto_scope ).to eq( manual_scope )
        end
      end
    end
  end

  context '#translate_errors_to' do
    include_context 'error mapping'

    it 'adds nothing if the model is valid' do
      m = valid_model
      expect( described_class.translate_errors_on( m ).errors ).to eq( [] )
      expect { m.save! }.to_not raise_error
    end

    it 'maps column types correctly' do
      m = RSpecModelErrorMappingTest.new( :uuid => 'not a valid UUID' )
      m.validate()

      expect( described_class.translate_errors_on( m ).errors ).to eq( [
        {
          "code" => "generic.invalid_boolean",
          "message" => "can't be blank",
          "reference" => "boolean"
        },
        {
          "code" => "generic.invalid_date",
          "message" => "can't be blank",
          "reference" => "date"
        },
        {
          "code" => "generic.invalid_datetime",
          "message" => "can't be blank",
          "reference" => "datetime"
        },
        {
          "code" => "generic.invalid_decimal",
          "message" => "can't be blank",
          "reference" => "decimal"
        },
        {
          "code" => "generic.invalid_float",
          "message" => "can't be blank",
          "reference" => "float"
        },
        {
          "code" => "generic.invalid_integer",
          "message" => "can't be blank",
          "reference" => "integer"
        },
        {
          "code" => "generic.invalid_string",
          "message" => "can't be blank",
          "reference" => "string"
        },
        {
          "code" => "generic.invalid_string",
          "message" => "can't be blank",
          "reference" => "text"
        },
        {
          "code" => "generic.invalid_time",
          "message" => "can't be blank",
          "reference" => "time"
        },
        {
          "code" => "generic.invalid_array",
          "message" => "can't be blank",
          "reference" => "array"
        },

        # Checks that custom UUID validator is working.

        {
          "code" => "generic.invalid_uuid",
          "message" => "is invalid",
          "reference" => "uuid"
        }
      ] )
    end

    it 'maps "base" errors correctly' do
      m = RSpecModelErrorMappingTestBase.new

      m.validate()
      expect( described_class.translate_errors_on( m ).errors ).to eq( [
        {
          "code" => "generic.invalid_parameters",
          "message" => "this is a test",
          "reference" => "model instance"
        }
      ] )
    end

    it 'adds to an existing collection' do
      m = RSpecModelErrorMappingTestBase.new
      collection = Hoodoo::Errors.new

      collection.add_error( 'platform.timeout' )

      m.validate()
      expect( described_class.translate_errors_on( m, collection ).errors ).to eq( [
        {
          "code" => "platform.timeout",
          "message" => "Request timeout"
        },
        {
          "code" => "generic.invalid_parameters",
          "message" => "this is a test",
          "reference" => "model instance"
        }
      ] )
    end

    it 'handles varying validation types' do
      m = RSpecModelErrorMappingTest.new( {
        :boolean  => true,
        :date     => Time.now,
        :datetime => Time.now,
        :decimal  => 2.3,
        :float    => 2.3,
        :integer  => 42,
        :string   => "hello - this is far too long for the maximum field length",
        :text     => "hello",
        :time     => Time.now,
        :array    => [ 'hello' ]
      } )

      m.validate()
      expect( described_class.translate_errors_on( m ).errors ).to eq( [
        {
          "code" => "generic.invalid_string",
          "message" => "is too long (maximum is 16 characters)",
          "reference" => "string"
        }
      ] )
    end

    it 'handles arrays' do
      m = RSpecModelErrorMappingTest.new( {
        :boolean  => true,
        :date     => Time.now,
        :datetime => Time.now,
        :decimal  => 2.3,
        :float    => 2.3,
        :integer  => 42,
        :string   => 'hello',
        :text     => 'world',
        :time     => Time.now,
        :array    => []
      } )

      array_col = RSpecModelErrorMappingTest.columns_hash[ 'array' ]
      expect(array_col.array).to eq( true )

      m.validate()
      expect( described_class.translate_errors_on( m ).errors ).to eq( [
        {
          "code" => "generic.invalid_array",
          "message" => "can't be blank",
          "reference" => "array"
        }
      ] )
    end

    it 'maps duplicates' do
      m = valid_model

      m.validate()
      expect( described_class.translate_errors_on( m ).errors ).to eq( [] )
      m.save!

      n = m.dup
      n.validate()
      expect( described_class.translate_errors_on( n ).errors ).to eq( [
        {
          "code" => "generic.invalid_duplication",
          "message" => "has already been taken",
          "reference" => "integer"
        }
      ] )
    end

    context 'downgrade to generic error code' do
      class LocalHackableErrors < Hoodoo::ErrorDescriptions
      end

      # We have to hack to test this...
      #
      before :all do
        @collection = Hoodoo::Errors.new( Hoodoo::ErrorDescriptions.new )
        @desc       = @collection.descriptions.instance_variable_get( '@descriptions' )
        @val1       = @desc.delete( 'generic.invalid_boolean' )
        @val2       = @desc.delete( 'generic.invalid_date' )
      end

      after :all do
        @desc[ 'generic.invalid_boolean' ] = @val1
        @desc[ 'generic.invalid_date'    ] = @val2
      end

      it "is handled" do
        m = RSpecModelErrorMappingTest.new( {
          :datetime => Time.now,
          :decimal  => 2.3,
          :float    => 2.3,
          :integer  => 42,
          :string   => "hello",
          :text     => "hello",
          :time     => Time.now,
          :array    => [ 'hello' ]
        } )

        m.validate()
        expect( described_class.translate_errors_on( m, @collection ).errors ).to eq( [
          {
            "code" => "generic.invalid_parameters",
            "message" => "can't be blank",
            "reference" => "boolean"
          },
          {
            "code" => "generic.invalid_parameters",
            "message" => "can't be blank",
            "reference" => "date"
          }
        ] )
      end
    end

    it 'has-many associations are dereferenced' do
      attrs = valid_model.attributes
      attrs[ 'r_spec_model_associated_error_mapping_tests_attributes' ] = [
        { :other_string => 'ok 1' },
        { :other_string => 'ok 2' },
        { :other_string => 'too long, so fails validation' }
      ]

      m = RSpecModelErrorMappingTest.new( attrs )

      m.validate()
      expect( described_class.translate_errors_on( m ).errors ).to eq( [
        {
          "code" => "generic.invalid_string",
          "message" => "is too long (maximum is 6 characters)",
          "reference" => "r_spec_model_associated_error_mapping_tests.other_string"
        }
      ] )
    end

    it 'works with dot-separated non-attribute paths' do
      m = valid_model
      m.string = 'magic'

      m.validate()
      expect( described_class.translate_errors_on( m ).errors ).to eq( [
        {
          "code" => "generic.invalid_parameters",
          "message" => "is not a column",
          "reference" => "this.thing"
        }
      ] )
    end
  end
end
