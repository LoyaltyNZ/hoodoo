require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::UUID do
  before :all do
    spec_helper_silence_stdout() do
      tblname = :r_spec_model_uuid_tests

      ActiveRecord::Migration.create_table( tblname, :id => :string ) do | t |
      end

      ActiveRecord::Migration.change_column( tblname, :id, :string, :limit => 32 )

      class RSpecModelUUIDTest < ActiveRecord::Base
        include Hoodoo::ActiveRecord::UUID
      end
    end
  end

  it 'should gain a UUID' do
    m = RSpecModelUUIDTest.new
    m.save

    expect( m.id ).to_not be_nil
    expect( Hoodoo::UUID.valid?( m.id ) ).to eq( true )
  end

  it 'should complain about a bad UUID' do
    m = RSpecModelUUIDTest.new
    m.id = "hello"

    expect( m.save ).to eq( false )
    expect( Hoodoo::UUID.valid?( m.id ) ).to eq( false )
    expect( m.errors ).to_not be_empty
    expect( m.errors.messages ).to eq( { :id => [ 'is invalid' ] } )
  end

  it 'should not overwrite a good UUID' do
    m = RSpecModelUUIDTest.new
    uuid = Hoodoo::UUID.generate()
    m.id = uuid
    m.save

    expect( m.id ).to eq( uuid )
    expect( Hoodoo::UUID.valid?( m.id ) ).to eq( true )
  end

  # Accidental attribute assignment of "id" to "nil" on updates can cause
  # really bad consequences if the UUID is then automatically assigned again;
  # the resource primary key would change magically! Never allow this. If a
  # primary key change is ever wanted, a new UUID must be explicitly given.
  #
  it 'should not update with a replacement UUID' do
    m = RSpecModelUUIDTest.new
    m.save!
    id = m.id

    # So it shouldn't save with a 'nil' ID...

    m.assign_attributes( :id => nil )

    expect( m.save ).to eq( false )
    expect( m.errors.messages ).to eq( { :id => [ "can't be blank" ] } )

    # ...and should be able to reload it with the original ID still.

    m.id = id
    m.reload
    expect( m.id ).to eq( id )
  end

  it 'should not allow a duplicate UUID at the application level' do
    m = RSpecModelUUIDTest.new
    m.save

    n = RSpecModelUUIDTest.new
    n.id = m.id

    expect( n ).to be_invalid
    expect( n.errors[ :id ] ).to eq( [ 'has already been taken' ] )
  end
end
