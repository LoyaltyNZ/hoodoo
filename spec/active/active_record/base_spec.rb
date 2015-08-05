require 'spec_helper'
require 'active_record'

describe Hoodoo::ActiveRecord::Base do
  before :all do
    spec_helper_silence_stdout() do
      tblname = :r_spec_model_base_tests

      ActiveRecord::Migration.create_table( tblname, :id => false ) do | t |
        t.string( :id, :limit => 32, :null => false )
      end

      ActiveRecord::Migration.add_index( tblname, :id, :unique => true )

      class RSpecModelBaseTest < Hoodoo::ActiveRecord::Base
      end
    end
  end

  it 'gains a UUID' do
    m = RSpecModelBaseTest.new
    m.save

    expect( m.id ).to_not be_nil
    expect( Hoodoo::UUID.valid?( m.id ) ).to eq( true )
  end

  it 'has security capability' do
    expect( RSpecModelBaseTest ).to respond_to( :secure )
  end

  it 'has dating capability' do
    expect( RSpecModelBaseTest ).to respond_to( :dated )
  end

  it 'has internationalisation capability' do
    expect( RSpecModelBaseTest ).to respond_to( :translated )
  end

  it 'finds things' do
    m = RSpecModelBaseTest.new
    m.save
    expect( RSpecModelBaseTest.acquire( m.id ) ).to_not be_nil
  end

  it 'allows error mapping' do
    expect( RSpecModelBaseTest.new.platform_errors.has_errors? ).to eq( false )
  end
end
