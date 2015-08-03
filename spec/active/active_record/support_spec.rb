require 'spec_helper.rb'

describe Hoodoo::ActiveRecord::Support do
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
      expect( map[ 'foo' ].call( 'ignored', 'val1' ) ).to eq( [ { 'foo' => 'val1' } ] )

      expect( map[ 'bar' ] ).to be_a( Proc )
      expect( map[ 'bar' ].call( 'ignored', 'val2' ) ).to eq( [ { 'bar' => 'val2' } ] )

      expect( map[ 'baz' ] ).to eq( proc1 )

      expect( map[ 'boo' ] ).to eq( proc2 )
    end
  end

  context '#full_scope_for' do

    # Here we not only test the full scope generator with all mixins included,
    # and test them all in a *deactivated* state, we also check that inheritance
    # can then override that condition without disturbing the base class to
    # ensure that "class attribute" style code, rather than "@@" class variable
    # style code, is being maintained in the mixins.

    before :all do

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

      spec_helper_silence_stdout() do
        ActiveRecord::Migration.create_table( :r_spec_full_scope_for_test_bases ) do | t |
          t.timestamps :null => true
        end

        ActiveRecord::Migration.create_table( :r_spec_full_scope_for_test_subclasses ) do | t |
          t.string :foo
          t.timestamps :null => true
        end

        ActiveRecord::Migration.create_table( :r_spec_full_scope_for_test_foo_history ) do | t |
          t.string :foo
          t.timestamps :null => true
        end
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

    it 'prerequisites for testing' do
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

    it 'gets customised scope in the subclass' do

      # All activations are in the subclass so we drive the non-context
      # versions directly to verify that the context chain worked.

      auto_scope   = described_class.full_scope_for( RSpecFullScopeForTestSubclass, @context ).to_sql()
      manual_scope = RSpecFullScopeForTestSubclass.secure( @context ).dated( @context ).translated( @context ).to_sql()

      expect( auto_scope ).to eq( manual_scope )
      expect( auto_scope ).to include( "\"r_spec_full_scope_for_test_subclasses\".\"foo\" = '#{ @test_scoping_value }'" )
      expect( auto_scope ).to include( "FROM #{ RSpecFullScopeForTestSubclass::TEST_HISTORY_TABLE_NAME }" )
      expect( auto_scope ).to include( "effective_end > #{ RSpecFullScopeForTestSubclass.sanitize( @test_time_value ) }" )
    end

  end
end
