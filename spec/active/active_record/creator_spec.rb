require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Creator do
  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_creator_tests, :id => :string ) do | t |
        t.text :code
        t.text :field_one

        t.timestamps
      end
    end

    class RSpecModelCreatorTest < ActiveRecord::Base
      include Hoodoo::ActiveRecord::Creator
      include Hoodoo::ActiveRecord::Dated
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

    it 'creates with specified dated-from value' do
      time = Time.now.iso8601
      @context.request.dated_from = time

      instance = RSpecModelCreatorTest.new_in( @context )

      expect( instance.created_at.iso8601 ).to eq( time )
      expect( instance.updated_at.iso8601 ).to eq( time )
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
