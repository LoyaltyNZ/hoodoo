require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::UUID do
  before :all do
    spec_helper_silence_stdout() do
      tblname = :r_spec_model_uuid_tests

      ActiveRecord::Migration.create_table( tblname, :id => false ) do | t |
        t.string( :id, :limit => 32, :null => false )
      end

      ActiveRecord::Migration.add_index( tblname, :id, :unique => true )

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
end
