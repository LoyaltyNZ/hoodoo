require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Secure do
  before :all do

    spec_helper_silence_stdout() do

      migration = Proc.new do | t |
        t.text :creator
        t.text :distributor
        t.text :field

        t.timestamps
      end

      ActiveRecord::Migration.create_table( :r_spec_model_secure_test_as, &migration )
      ActiveRecord::Migration.create_table( :r_spec_model_secure_test_bs, &migration )
      ActiveRecord::Migration.create_table( :r_spec_model_secure_test_cs, &migration )

      class RSpecModelSecureTestA < ActiveRecord::Base
        include Hoodoo::ActiveRecord::Secure

        secure_with(
          :creator      => 'authorised_creators',  # Array
          'distributor' => :authorised_distributor # Single item
        )
      end

      class RSpecModelSecureTestB < ActiveRecord::Base
        include Hoodoo::ActiveRecord::Secure

        secure_with(
          :creator      => { :session_field_name => 'authorised_creators'   },
          'distributor' => { :session_field_name => :authorised_distributor } # Single item
        )
      end

      class RSpecModelSecureTestC < ActiveRecord::Base
        include Hoodoo::ActiveRecord::Secure

        # Custom Proc matching "or", straight out of the #secure RDoc
        # but with our required column name of "distributor" inserted.
        #
        or_matcher = Proc.new do | model_class, database_column_name, session_field_value |

          # This example works for non-array and array field values.
          #
          session_field_value = [ session_field_value ].flatten
          session_field_value = session_field_value.join( ', ' )

          [
            "\"#{ database_column_name }\" IN (?) OR \"distributor\" IN (?)",
            session_field_value,
            session_field_value
          ]
        end

        secure_with(
          :creator => {
            :session_field_name => 'authorised_creators',
            :using              => or_matcher
          }
        )
      end
    end
  end

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

  shared_examples 'a secure model' do
    before :each do
      @scoped_1 = @class_to_test.new
      @scoped_1.creator     =     'creator 1'
      @scoped_1.distributor = 'distributor 1'
      @scoped_1.field       =      'scoped 1'
      @scoped_1.save!

      @scoped_2 = @class_to_test.new
      @scoped_2.creator     =     'creator 1'
      @scoped_2.distributor = 'distributor 2'
      @scoped_2.field       =      'scoped 2'
      @scoped_2.save!

      @scoped_3 = @class_to_test.new
      @scoped_3.creator     =     'creator 2'
      @scoped_3.distributor = 'distributor 2'
      @scoped_3.field       =      'scoped 3'
      @scoped_3.save!
    end

    it 'finds with secure scopes from the class' do
      @session.scoping = { :authorised_creators => [ 'creator 1' ], :authorised_distributor => 'distributor 1' }

      found = @class_to_test.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to eq( @scoped_1 )

      found = @class_to_test.secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to be_nil

      found = @class_to_test.secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to be_nil

      @session.scoping.authorised_distributor = 'distributor 2'

      found = @class_to_test.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil

      found = @class_to_test.secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to eq( @scoped_2 )

      found = @class_to_test.secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to be_nil

      @session.scoping.authorised_creators = [ 'creator 2' ]

      found = @class_to_test.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil

      found = @class_to_test.secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to be_nil

      found = @class_to_test.secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to eq( @scoped_3 )

      @session.scoping.authorised_creators = [ 'creator 1', 'creator 2' ]

      found = @class_to_test.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil

      found = @class_to_test.secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to eq( @scoped_2 )

      found = @class_to_test.secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to eq( @scoped_3 )
    end

    it 'finds with secure scopes with a chain' do
      @session.scoping = { :authorised_creators => [ 'creator 1' ], :authorised_distributor => 'distributor 1' }

      found = @class_to_test.where( :field => @scoped_1.field ).secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to eq( @scoped_1 )

      found = @class_to_test.where( :field => @scoped_1.field + '!' ).secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil

      found = @class_to_test.where( :field => @scoped_2.field ).secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to be_nil

      found = @class_to_test.where( :field => @scoped_3.field ).secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to be_nil

      @session.scoping.authorised_creators = [ 'creator 1', 'creator 2' ]
      @session.scoping.authorised_distributor  = 'distributor 2'

      found = @class_to_test.where( :field => @scoped_1.field ).secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil

      found = @class_to_test.where( :field => @scoped_2.field ).secure( @context ).find_by_id( @scoped_2.id )
      expect( found ).to eq( @scoped_2 )

      found = @class_to_test.where( :field => @scoped_3.field ).secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to eq( @scoped_3 )

      found = @class_to_test.where( :field => @scoped_3.field + '!' ).secure( @context ).find_by_id( @scoped_3.id )
      expect( found ).to be_nil
    end

    it 'finds nothing if scope lacks required keys' do
      @session.scoping = { :authorised_distributor => 'distributor 1' }

      found = @class_to_test.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil
    end

    it 'finds nothing if scope is missing' do
      found = @class_to_test.secure( @context ).find_by_id( @scoped_1.id )
      expect( found ).to be_nil
    end
  end

  context 'works with a Symbol' do
    before( :all ) { @class_to_test = RSpecModelSecureTestA }
    it_behaves_like 'a secure model'
  end

  context 'works with a Hash' do
    before( :all ) { @class_to_test = RSpecModelSecureTestB }
    it_behaves_like 'a secure model'
  end

  context 'works with custom Procs' do
    before :each do
      @scoped_4 = RSpecModelSecureTestC.new
      @scoped_4.creator     =     'creator 3'
      @scoped_4.distributor =       'nothing'
      @scoped_4.field       =      'scoped 3'
      @scoped_4.save!

      @scoped_5 = RSpecModelSecureTestC.new
      @scoped_5.creator     =       'nothing'
      @scoped_5.distributor =     'creator 3'
      @scoped_5.field       =      'scoped 3'
      @scoped_5.save!

      @scoped_6 = RSpecModelSecureTestC.new
      @scoped_6.creator     =       'nothing'
      @scoped_6.distributor =       'nothing'
      @scoped_6.field       =      'scoped 3'
      @scoped_6.save!
    end

    it 'finds with secure scopes from the class' do
      @session.scoping = { :authorised_creators => [ 'creator 3' ] }

      found = RSpecModelSecureTestC.secure( @context ).find_by_id( @scoped_4.id )
      expect( found ).to eq( @scoped_4 )

      found = RSpecModelSecureTestC.secure( @context ).find_by_id( @scoped_5.id )
      expect( found ).to eq( @scoped_5 )

      found = RSpecModelSecureTestC.secure( @context ).find_by_id( @scoped_6.id )
      expect( found ).to be_nil
    end

    it 'finds with secure scopes with a chain' do
      @session.scoping = { :authorised_creators => [ 'creator 3' ] }

      found = RSpecModelSecureTestC.where( :field => @scoped_4.field ).secure( @context ).find_by_id( @scoped_4.id )
      expect( found ).to eq( @scoped_4 )

      found = RSpecModelSecureTestC.where( :field => @scoped_4.field + '!' ).secure( @context ).find_by_id( @scoped_4.id )
      expect( found ).to be_nil

      found = RSpecModelSecureTestC.where( :field => @scoped_5.field ).secure( @context ).find_by_id( @scoped_5.id )
      expect( found ).to eq( @scoped_5 )

      found = RSpecModelSecureTestC.where( :field => @scoped_5.field + '!' ).secure( @context ).find_by_id( @scoped_5.id )
      expect( found ).to be_nil
    end

    it 'finds nothing if scope lacks required keys' do
      @session.scoping = { :authorised_creators => [ 'missing' ] }

      found = RSpecModelSecureTestC.secure( @context ).find_by_id( @scoped_4.id )
      expect( found ).to be_nil
    end

    it 'finds nothing if scope is missing' do
      found = RSpecModelSecureTestC.secure( @context ).find_by_id( @scoped_4.id )
      expect( found ).to be_nil
    end
  end

  # See also presenters/base_spec.rb
  #
  context 'rendering' do
    class RSpecModelSecureRenderA < ActiveRecord::Base
      include Hoodoo::ActiveRecord::Secure

      secure_with( {
        :creating_caller_uuid => :authorised_caller_uuids,
        :programme_code       => :authorised_programme_codes
      } )
    end

    class RSpecModelSecureRenderB < ActiveRecord::Base
      include Hoodoo::ActiveRecord::Secure

      secure_with( {
        :creating_caller_uuid => {
          :session_field_name  => :authorised_caller_uuids,
          :resource_field_name => :caller_id # Note renaming of field
        },

        :programme_code => {
          :session_field_name => :authorised_programme_codes,
          :hide_from_resource => true
        }
      } )
    end

    # Same as RSpecModelSecureRenderB, but includes a ":using" key. We
    # really don't expect this to change anything, but test coverage is
    # included just in case. By coping 'B', we can just duplicate the
    # tests of 'B' and expect identical results for 'C'.

    class RSpecModelSecureRenderC < ActiveRecord::Base
      include Hoodoo::ActiveRecord::Secure

      # Matches Secure's DEFAULT_SECURE_PROC at the time of writing, but
      # I don't want to reference that internal constant here in case (say)
      # its name changes in future.
      #
      simple_matcher = Proc.new { | model_class, database_column_name, session_field_value |
        [ { database_column_name => session_field_value } ]
      }

      secure_with( {
        :creating_caller_uuid => {
          :session_field_name  => :authorised_caller_uuids,
          :resource_field_name => :caller_id, # Note renaming of field
          :using               => simple_matcher
        },

        :programme_code => {
          :session_field_name => :authorised_programme_codes,
          :hide_from_resource => true
        }
      } )
    end

    before :all do
      spec_helper_silence_stdout() do

        # This is set up to match examples in the RDoc data for #secure(_with)
        # at the time of writing.

        migration = Proc.new do | t |
          t.text :creating_caller_uuid
          t.text :programme_code
          t.timestamps
        end

        ActiveRecord::Migration.create_table( :r_spec_model_secure_render_as, &migration )
        ActiveRecord::Migration.create_table( :r_spec_model_secure_render_bs, &migration )
        ActiveRecord::Migration.create_table( :r_spec_model_secure_render_cs, &migration )
      end
    end

    before :each do
      @authorised_caller_uuids = [
        Hoodoo::UUID.generate,
        Hoodoo::UUID.generate,
        Hoodoo::UUID.generate
      ]

      @authorised_programme_codes = [
        'AA',
        'BB'
      ]

      @session.scoping = { 'authorised_caller_uuids'    => @authorised_caller_uuids,
                           'authorised_programme_codes' => @authorised_programme_codes }

      [ RSpecModelSecureRenderA, RSpecModelSecureRenderB, RSpecModelSecureRenderC ].each do | klass |
        item = klass.new
        item.programme_code = @authorised_programme_codes.last
        item.creating_caller_uuid = @authorised_caller_uuids.last
        item.save!
      end
    end

    class TestPresenterSecure < Hoodoo::Presenters::Base
      schema do
        string :three, :length => 15, :required => false, :default => 'default_three'
        internationalised
      end
    end

    it 'renders with default security' do
      found = RSpecModelSecureRenderA.secure( @context ).first
      expect( found ).to_not be_nil

      data = {}
      t = Time.now.utc
      u = Hoodoo::UUID.generate
      options = { :uuid => u, :created_at => t, :secured_with => found }
      expect(TestPresenterSecure.render_in(@context, data, options)).to eq({
        'id'           => u,
        'kind'         => 'TestPresenterSecure',
        'created_at'   => t.iso8601,
        'language'     => 'en-nz',
        'three'        => 'default_three',
        'secured_with' => {
          'creating_caller_uuid' => found.creating_caller_uuid,
          'programme_code'       => found.programme_code
        }
      })
    end

    it 'renders with custom security' do
      found = RSpecModelSecureRenderB.secure( @context ).first
      expect( found ).to_not be_nil

      data = {}
      t = Time.now.utc
      u = Hoodoo::UUID.generate
      options = { :uuid => u, :created_at => t, :secured_with => found }
      expect(TestPresenterSecure.render_in(@context, data, options)).to eq({
        'id'           => u,
        'kind'         => 'TestPresenterSecure',
        'created_at'   => t.iso8601,
        'language'     => 'en-nz',
        'three'        => 'default_three',
        'secured_with' => {
          'caller_id' => found.creating_caller_uuid
        }
      })
    end

    it 'renders with custom security and custom matcher' do
      found = RSpecModelSecureRenderC.secure( @context ).first
      expect( found ).to_not be_nil

      data = {}
      t = Time.now.utc
      u = Hoodoo::UUID.generate
      options = { :uuid => u, :created_at => t, :secured_with => found }
      expect(TestPresenterSecure.render_in(@context, data, options)).to eq({
        'id'           => u,
        'kind'         => 'TestPresenterSecure',
        'created_at'   => t.iso8601,
        'language'     => 'en-nz',
        'three'        => 'default_three',
        'secured_with' => {
          'caller_id' => found.creating_caller_uuid
        }
      })
    end
  end
end
