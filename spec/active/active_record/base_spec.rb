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

  it 'is secure' do
    expect { RSpecModelBaseTest.secure_with( {} ) }.to_not raise_exception()
  end

  it 'finds things' do
    m = RSpecModelBaseTest.new
    m.save
    expect( RSpecModelBaseTest.acquire( m.id ) ).to_not be_nil
  end

  it 'allows error mapping' do
    expect( RSpecModelBaseTest.new.platform_errors.has_errors? ).to eq( false )
  end

  it 'acquires context from all included modules' do
    expect( RSpecModelBaseTest ).to receive( :secure     ).and_return( RSpecModelBaseTest.all() )

    m = RSpecModelBaseTest.new
    m.save

    # Fragile test relies upon knowing *exactly* what stuff 'acquire_in' pulls
    # from 'context', in conjunction with the mocking of the various scope
    # mechanisms above in the "expect" calls.

    context = OpenStruct.new
    context.request = OpenStruct.new
    context.request.ident = m.id

    # Implicit test of Hoodoo::ActiveRecord::Support#full_scope_for here.

    RSpecModelBaseTest.acquire_in( context )
  end
end
