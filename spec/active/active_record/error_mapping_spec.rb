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

      class RSpecModelErrorMappingTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::ErrorMapping

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
      end
    end
  end

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

  it 'does not auto-validate if so instructed' do
    m = RSpecModelErrorMappingTest.new

    expect( m.adds_errors_to?( @errors, false ) ).to eq( false )
    expect( m ).to_not receive( :valid? )

    expect( @errors.errors ).to eq( [] )
  end

  it 'maps "base" errors correctly' do
    m = RSpecModelErrorMappingTest.new
    m.errors.add( :base, 'this is a test' )

    # The error added above would be cleared if we let validation happen as
    # the first thing AR does for this is clear any existing erorrs out. So,
    # having manually added an error, pass "false" to "adds_errors_to?" to
    # prevent re-validation (see test "it 'does not auto-validate if so
    # instructed'") and deal just with the model's existing error collection.

    expect( m.adds_errors_to?( @errors, false ) ).to eq( true )
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
    expect(array_col).to receive(:array).once.and_return(true)

    m.valid?
    m.adds_errors_to?( @errors, false )

    expect( @errors.errors ).to eq( [
      {
        "code" => "generic.invalid_array",
        "message" => "can't be blank",
        "reference" => "array"
      }
    ] )
  end

  it 'maps duplicates' do
    m = RSpecModelErrorMappingTest.new( {
      :uuid      => Hoodoo::UUID.generate(),
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
    m = RSpecModelErrorMappingTest.new( {
      :uuid      => Hoodoo::UUID.generate(),
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

    expect( m.adds_errors_to?( @errors ) ).to eq( false )
    expect( @errors.errors ).to eq( [] )

    expect { m.save! }.to_not raise_error
  end
end
