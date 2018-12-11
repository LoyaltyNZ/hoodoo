require 'spec_helper'
require 'active_record'
require 'active/active_record/error_mapping_shared_context'

describe Hoodoo::ActiveRecord::ErrorMapping do
  include_context 'error mapping'

  before :each do
    @errors = Hoodoo::Errors.new( Hoodoo::ErrorDescriptions.new )
  end

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

      m.adds_errors_to?( @collection )

      expect( @collection.errors ).to eq( [
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
