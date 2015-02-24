require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Secure do
  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_secure_tests ) do | t |
        t.text :creator
        t.text :distributor
        t.text :field

        t.timestamps
      end

      class RSpecModelSecureTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::Secure

        secure_with(
          :creator      => 'authorised_creators',   # Array
          'distributor' => 'authorised_distributor' # Single item
        )
      end
    end
  end

  context '#secure and #secure_with' do
    before :each do
      @scoped_1 = RSpecModelSecureTest.new
      @scoped_1.creator     =     'creator 1'
      @scoped_1.distributor = 'distributor 1'
      @scoped_1.field            = 'scoped 1'
      @scoped_1.save!

      @scoped_2 = RSpecModelSecureTest.new
      @scoped_2.creator         = 'creator 1'
      @scoped_2.distributor = 'distributor 2'
      @scoped_2.field            = 'scoped 2'
      @scoped_2.save!

      @scoped_3 = RSpecModelSecureTest.new
      @scoped_3.creator         = 'creator 2'
      @scoped_3.distributor = 'distributor 2'
      @scoped_3.field            = 'scoped 3'
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

    it 'finds with secure scopes from the class' do
      @session.scoping = { :authorised_creators => [ 'creator 1' ], :authorised_distributor => 'distributor 1' }

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to eq( @scoped_1 )

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to be_nil

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to be_nil

      @session.scoping.authorised_distributor = 'distributor 2'

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to eq( @scoped_2 )

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to be_nil

      @session.scoping.authorised_creators = [ 'creator 2' ]

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to be_nil

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to eq( @scoped_3 )

      @session.scoping.authorised_creators = [ 'creator 1', 'creator 2' ]

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to eq( @scoped_2 )

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to eq( @scoped_3 )
    end

    it 'finds with secure scopes with a chain' do
      @session.scoping = { :authorised_creators => [ 'creator 1' ], :authorised_distributor => 'distributor 1' }

      found = RSpecModelSecureTest.where( :field => @scoped_1.field ).secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to eq( @scoped_1 )

      found = RSpecModelSecureTest.where( :field => @scoped_1.field + '!' ).secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil

      found = RSpecModelSecureTest.where( :field => @scoped_2.field ).secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to be_nil

      found = RSpecModelSecureTest.where( :field => @scoped_3.field ).secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to be_nil

      @session.scoping.authorised_creators = [ 'creator 1', 'creator 2' ]
      @session.scoping.authorised_distributor  = 'distributor 2'

      found = RSpecModelSecureTest.where( :field => @scoped_1.field ).secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil

      found = RSpecModelSecureTest.where( :field => @scoped_2.field ).secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to eq( @scoped_2 )

      found = RSpecModelSecureTest.where( :field => @scoped_3.field ).secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to eq( @scoped_3 )

      found = RSpecModelSecureTest.where( :field => @scoped_3.field + '!' ).secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to be_nil
    end

    it 'finds nothing if scope lacks required keys' do
      @session.scoping = { :authorised_distributor => 'distributor 1' }

      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil
    end

    it 'finds nothing if scope is missing' do
      found = RSpecModelSecureTest.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil
    end
  end
end
