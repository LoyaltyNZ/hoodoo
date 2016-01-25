require 'spec_helper.rb'

describe Hoodoo::Services::Middleware::AMQPLogMessage do

  let( :now       ) { Time.now }
  let( :base_hash ) {
    {
      :id => '1',
      :level => 'info',
      :component => 'RSpec',
      :code => 'hello',

      :data => { 'this' => 'that' },

      :interaction_id => '3',
      :caller_id => '2',
      :identity => { :foo => '4', :bar => '5' },
    }
  }

  ############################################################################
  # All tests must use 'let' to define values for 'reported_at' and
  # 'expected_reported_at'.
  ############################################################################

  let( :hash            ) { base_hash().merge( :reported_at => reported_at() ) }
  let( :expected_result ) {
    Hoodoo::Utilities.stringify( hash() ).merge( 'reported_at' => expected_reported_at() )
  }

  shared_examples 'a well formed logger' do
    it 'and canonicalises the fields' do
      obj = described_class.new( hash() )
      expect( obj.to_h ).to eq( expected_result() )
    end
  end

  context 'with a Time object in "reported_at"' do
    let( :reported_at          ) { Time.now }
    let( :expected_reported_at ) { reported_at().strftime( Hoodoo::Services::Middleware::AMQPLogMessage::TIME_FORMATTER ) }

    it_behaves_like 'a well formed logger'
  end

  context 'with a String object in "reported_at"' do
    let( :reported_at          ) { Time.now.iso8601 }
    let( :expected_reported_at ) { reported_at()    }

    it_behaves_like 'a well formed logger'
  end

  context 'with "nil" in "reported_at"' do
    let( :reported_at          ) { nil           }
    let( :expected_reported_at ) { reported_at() }

    it_behaves_like 'a well formed logger'
  end
end
