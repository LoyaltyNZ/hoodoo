require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::ErrorMapping do
  before :all do
    spec_helper_silence_stdout() do
      ActiveRecord::Migration.create_table( :r_spec_model_error_mapping_tests ) do | t |
        t.string   :uuid
        t.boolean  :boolean
        t.date     :date
        t.datetime :datetime
        t.decimal  :decimal, :precision => 5, :scale => 2
        t.float    :float
        t.integer  :integer
        t.string   :string, :limit => 16
        t.text     :text
        t.time     :time
        t.text     :array, :array => true
      end

      ActiveRecord::Migration.create_table( :r_spec_model_associated_error_mapping_tests ) do | t |
        t.string :other_string

        # For 'has_many' - can't use "t.reference" as the generated
        # column name is too long!
        #
        t.integer :many_id
        t.index   :many_id
      end

      class RSpecModelErrorMappingTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::ErrorMapping

        has_many :r_spec_model_associated_error_mapping_tests,
                 :foreign_key => :many_id,
                 :class_name  => :RSpecModelAssociatedErrorMappingTest

        accepts_nested_attributes_for :r_spec_model_associated_error_mapping_tests

        validates_presence_of :boolean,
                              :date,
                              :datetime,
                              :decimal,
                              :float,
                              :integer,
                              :string,
                              :text,
                              :time,
                              :array

        validates_uniqueness_of :integer
        validates :string, :length => { :maximum => 16 }
        validates :uuid, :uuid => true

        validate do
          if string == 'magic'
            errors.add( 'this.thing', 'is not a column' )
          end
        end
      end

      class RSpecModelAssociatedErrorMappingTest < ActiveRecord::Base
        belongs_to :r_spec_model_error_mapping_test,
                   :foreign_key => :many_id,
                   :class_name  => :RSpecModelErrorMappingTest

        validates :other_string, :length => { :maximum => 6 }
      end

      class RSpecModelErrorMappingTestBase < ActiveRecord::Base
        self.table_name = RSpecModelErrorMappingTest.table_name

        include Hoodoo::ActiveRecord::ErrorMapping

        validate do | instance |
          instance.errors.add( :base, 'this is a test' )
        end
      end
    end
  end

  before :each do
    @errors = Hoodoo::Errors.new( Hoodoo::ErrorDescriptions.new )
  end

  let( :valid_model ) {
    RSpecModelErrorMappingTest.new( {
      :uuid     => Hoodoo::UUID.generate(),
      :boolean  => true,
      :date     => Time.now,
      :datetime => Time.now,
      :decimal  => 2.3,
      :float    => 2.3,
      :integer  => 42,
      :string   => "hello",
      :text     => "hello",
      :time     => Time.now,
      :array    => [ 'hello' ]
    } )
  }

  it 'auto-validates and maps errors correctly' do

    m = RSpecModelErrorMappingTest.new( :uuid => 'not a valid UUID' )
    expect( m.adds_errors_to?( @errors ) ).to eq( true )

    expect( @errors.errors ).to eq( [
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

    expect( m.adds_errors_to?( @errors ) ).to eq( true )
    expect( @errors.errors ).to eq( [
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

    m.adds_errors_to?( @errors )
    expect( @errors.errors ).to eq( [
      {
        "code" => "generic.invalid_string",
        "message" => "is too long (maximum is 16 characters)",
        "reference" => "string"
      }
    ] )
  end

  it 'handles varying validation types via the alternative interface' do
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

    errors = m.platform_errors
    expect( errors.errors ).to eq( [
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
    expect( array_col ).to receive( :array ).once.and_return( true )

    m.adds_errors_to?( @errors )

    expect( @errors.errors ).to eq( [
      {
        "code" => "generic.invalid_array",
        "message" => "can't be blank",
        "reference" => "array"
      }
    ] )
  end

  it 'maps duplicates' do
    m = valid_model

    m.adds_errors_to?( @errors )
    expect( @errors.errors ).to eq( [] )
    m.save!

    n = m.dup
    n.adds_errors_to?( @errors )
    expect( @errors.errors ).to eq( [
      {
        "code" => "generic.invalid_duplication",
        "message" => "has already been taken",
        "reference" => "integer"
      }
    ] )
  end

  it 'handles downgrade to generic error code' do

    class LocalHackableErrors < Hoodoo::ErrorDescriptions
    end

    @errors = Hoodoo::Errors.new( Hoodoo::ErrorDescriptions.new )

    # We have to hack to test this...
    #
    desc = @errors.descriptions.instance_variable_get( '@descriptions' )
    desc.delete( 'generic.invalid_boolean' )
    desc.delete( 'generic.invalid_date' )

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

    m.adds_errors_to?( @errors )

    expect( @errors.errors ).to eq( [
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

  it 'adds nothing if the model is valid' do
    m = valid_model

    expect( m.adds_errors_to?( @errors ) ).to eq( false )
    expect( @errors.errors ).to eq( [] )

    expect { m.save! }.to_not raise_error
  end

  it 'has-many associations are dereferenced' do
    attrs = valid_model.attributes
    attrs[ 'r_spec_model_associated_error_mapping_tests_attributes' ] = [
      { :other_string => 'ok 1' },
      { :other_string => 'ok 2' },
      { :other_string => 'too long, so fails validation' }
    ]

    m = RSpecModelErrorMappingTest.new( attrs )

    m.adds_errors_to?( @errors )

    expect( @errors.errors ).to eq( [
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

    m.adds_errors_to?( @errors )

    expect( @errors.errors ).to eq( [
      {
        "code" => "generic.invalid_parameters",
        "message" => "is not a column",
        "reference" => "this.thing"
      }
    ] )
  end
end
