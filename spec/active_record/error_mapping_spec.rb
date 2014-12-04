require 'spec_helper'
require 'active_record'

describe ApiTools::ActiveRecord::ErrorMapping do
  before :all do
    spec_helper_define_model() do
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

        # At time of writing SQLite (or at least, its ActiveRecord adapter)
        # does not support arrays, but the test case is included here for
        # possible future improvements.

        t.text     :array, :array => true
      end

      class RSpecModelErrorMappingTest < ActiveRecord::Base
        include ApiTools::ActiveRecord::ErrorMapping

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
    @errors = ApiTools::Errors.new( ApiTools::ErrorDescriptions.new )
  end

  it 'auto-validates and maps errors correctly' do

    m = RSpecModelErrorMappingTest.new( :uuid => 'not a valid UUID' )
    m.add_errors_to( @errors )

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

      # As per earlier comments, SQLite's adapter doesn't support array column
      # types at the time of writing so this ends up as "invalid_string".
      #
      # If tests start to fail because this is saying "invalid_array" - good!
      # It means SQLite's adapter has caught up and this expected error
      # message below should be fixed (by detecting the presence of the feature
      # in ActiveRecord::ConnectionAdapters::SQLite3Column or by ensuring that
      # a new enough adapter is definitely present).

      {
        "code" => "generic.invalid_string",
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
    m.add_errors_to( @errors, false )
    expect(m).to_not receive(:valid?)

    expect( @errors.errors ).to eq( [] )
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

    m.add_errors_to( @errors )
    expect( @errors.errors ).to eq( [
      {
        "code" => "generic.invalid_string",
        "message" => "is too long (maximum is 16 characters)",
        "reference" => "string"
      }
    ] )
  end

  # Nasty test for code coverage - patch the model to make the column
  # look like it really supports arrays and pass it a non-array type.

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
      :array    => 'not an array'
    } )

    array_col = RSpecModelErrorMappingTest.columns_hash[ 'array' ]
    expect(array_col).to receive(:array).once.and_return(true)

    # So long as there's no database support for arrays, ActiveRecord
    # won't add an error itself and the test will fail. So check first,
    # add our own error and call add_errors_to with "false" so that it
    # doesn't re-call "valid?", which doesn't add to any existing
    # errors as you might expect - instead it clears them. Thanks for
    # that, ActiveRecord.

    m.valid?
    m.errors.add( :array, 'custom message' ) if ( m.errors.messages.empty? )
    m.add_errors_to( @errors, false )

    expect( @errors.errors ).to eq( [
      {
        "code" => "generic.invalid_array",
        "message" => "custom message",
        "reference" => "array"
      }
    ] )
  end

  it 'maps duplicates' do
    m = RSpecModelErrorMappingTest.new( {
      :uuid      => ApiTools::UUID.generate(),
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

    m.add_errors_to( @errors )
    expect( @errors.errors ).to eq( [] )

    begin
      m.save!
    rescue TypeError
      m.array = 'This version of SQLite does not support arrays'
      m.save!
    end

    n = m.dup
    n.add_errors_to( @errors )
    expect( @errors.errors ).to eq( [
      {
        "code" => "generic.invalid_duplication",
        "message" => "has already been taken",
        "reference" => "integer"
      }
    ] )
  end

  it 'handles downgrade to generic error code' do

    class LocalHackableErrors < ApiTools::ErrorDescriptions
    end

    @errors = ApiTools::Errors.new( ApiTools::ErrorDescriptions.new )

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

    m.add_errors_to( @errors )

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
end
