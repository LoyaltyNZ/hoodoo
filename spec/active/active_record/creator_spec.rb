require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Creator do

  class RSpecModelCreatorTest < ActiveRecord::Base
    include Hoodoo::ActiveRecord::Creator
  end

  class RSpecModelCreatorTestManuallyDated < ActiveRecord::Base
    self.table_name = :r_spec_model_creator_tests

    include Hoodoo::ActiveRecord::Creator
    include Hoodoo::ActiveRecord::ManuallyDated
  end

  class RSpecModelCreatorTestAutoDated < ActiveRecord::Base
    self.table_name = :r_spec_model_creator_tests

    include Hoodoo::ActiveRecord::Creator
    include Hoodoo::ActiveRecord::Dated
  end

  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_creator_tests, :id => :string ) do | t |
        t.text :code
        t.text :field_one

        t.timestamps :null => true
      end
    end
  end

  # ==========================================================================

  context 'new_in' do
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

    shared_examples 'Creator-enabled model' do | klass |
      it 'creates with no special values' do
        instance = klass.new_in( @context )

        expect( instance.created_at ).to be_nil
        expect( instance.updated_at ).to be_nil
      end

      it 'creates with given values' do
        @time                       = Time.now
        @context.request.dated_from = @time

        instance = klass.new_in( @context )

        expect( instance.created_at ).to eq( @time )
        expect( instance.updated_at ).to eq( @time )
      end

      it 'creates with provided attributes' do
        instance = klass.new_in( @context, code: 'code', field_one: 'one' )

        expect( instance.code      ).to eq( 'code' )
        expect( instance.field_one ).to eq( 'one'  )
      end

      it 'creates with a block' do
        instance = klass.new_in( @context ) do | i |
          i.code      = 'code'
          i.field_one = 'one'
        end

        expect( instance.code      ).to eq( 'code' )
        expect( instance.field_one ).to eq( 'one'  )
      end

      # Technically ActiveRecord documentation seems to indicate this is an
      # either-or choice, but the code certainly supports both and it isn't
      # *explicitly* stated as such, so we assume both can be mixed here.
      #
      it 'creates with provided attributes and a block' do
        instance = klass.new_in( @context, code: 'code' ) do | i |
          i.field_one = 'one'
        end

        expect( instance.code      ).to eq( 'code' )
        expect( instance.field_one ).to eq( 'one'  )
      end
    end

    it_behaves_like 'Creator-enabled model', RSpecModelCreatorTest
    it_behaves_like 'Creator-enabled model', RSpecModelCreatorTestManuallyDated
    it_behaves_like 'Creator-enabled model', RSpecModelCreatorTestAutoDated
  end
end
