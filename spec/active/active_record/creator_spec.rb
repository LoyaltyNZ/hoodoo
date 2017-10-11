require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Creator do
  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_creator_tests, :id => :string ) do | t |
        t.text :code
        t.text :field_one

        t.timestamps :null => true
      end
    end

    class RSpecModelCreatorTest < ActiveRecord::Base
      include Hoodoo::ActiveRecord::Creator
      include Hoodoo::ActiveRecord::Dated
      include Hoodoo::ActiveRecord::ManuallyDated
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

    it 'creates with no special values' do
      instance = RSpecModelCreatorTest.new_in( @context )

      expect( instance.created_at ).to be_nil
      expect( instance.updated_at ).to be_nil
    end

    context 'with "dated_from" given' do
      before :each do
        @time                       = Time.now
        @context.request.dated_from = @time
      end

      shared_examples 'a dated model' do
        it 'using the specified dated-from value' do
          instance = RSpecModelCreatorTest.new_in( @context )

          expect( instance.created_at ).to eq( @time )
          expect( instance.updated_at ).to eq( @time )
        end
      end

      shared_examples 'a normal model' do
        it 'creating with no default timestamps' do
          instance = RSpecModelCreatorTest.new_in( @context )

          expect( instance.created_at ).to eq( nil )
          expect( instance.updated_at ).to eq( nil )
        end
      end

      context 'automatic dating present' do
        context 'and enabled it' do
          before :each do
            expect( RSpecModelCreatorTest ).to receive( :dating_enabled? ).once.and_return( true )
          end

          it_behaves_like 'a dated model'
        end

        context 'and not enabled it' do
          it_behaves_like 'a normal model'
        end
      end

      context 'manual dating present' do
        context 'and enabled it' do
          before :each do
            expect( RSpecModelCreatorTest ).to receive( :manual_dating_enabled? ).once.and_return( true )
          end

          it_behaves_like 'a dated model'
        end

        context 'and not enabled it' do
          it_behaves_like 'a normal model'
        end
      end
    end

    it 'creates with provided attributes' do
      instance = RSpecModelCreatorTest.new_in( @context, code: 'code', field_one: 'one' )

      expect( instance.code      ).to eq( 'code' )
      expect( instance.field_one ).to eq( 'one'  )
    end

    it 'creates with a block' do
      instance = RSpecModelCreatorTest.new_in( @context ) do | i |
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
      instance = RSpecModelCreatorTest.new_in( @context, code: 'code' ) do | i |
        i.field_one = 'one'
      end

      expect( instance.code      ).to eq( 'code' )
      expect( instance.field_one ).to eq( 'one'  )
    end
  end
end
