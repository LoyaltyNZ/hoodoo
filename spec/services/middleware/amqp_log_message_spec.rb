require 'spec_helper.rb'

describe Hoodoo::Services::Middleware::AMQPLogMessage do

  require 'msgpack'

  let( :now ) do
    Time.now
  end

  let( :source_hash ) do
    {
      :id => '1',
      :level => 'info',
      :component => 'RSpec',
      :code => 'hello',

      :data => { 'this' => 'that' },

      :interaction_id => '3',
      :caller_id => '2',
      :identity => { :foo => '4', :bar => '5' }
    }
  end

  let( :hash ) do
    source_hash().merge( :reported_at => now() )
  end

  let( :compare_hash ) do
    Hoodoo::Utilities.stringify(
      source_hash().merge(
        :reported_at => now().strftime( Hoodoo::Services::Middleware::AMQPLogMessage::TIME_FORMATTER )
      )
    )
  end

  it 'serializes' do
    obj = described_class.new( hash )
    expect( MessagePack.unpack( obj.serialize ) ).to eq( compare_hash )
  end

  it 'deserializes' do
    obj = described_class.new( hash )
    expect( MessagePack.unpack( obj.serialize ) ).to eq( compare_hash )
    obj.id = nil # Clear some instance vars
    obj.level = nil
    obj.deserialize # Should reset instance vars based on prior serialization
    expect( MessagePack.unpack( obj.serialize ) ).to eq( compare_hash )
  end

  it 'handles nil' do
    local_compare_hash = Hoodoo::Utilities.stringify(
      source_hash.merge( :reported_at => nil )
    )

    obj = described_class.new( source_hash )
    expect( MessagePack.unpack( obj.serialize ) ).to eq( local_compare_hash )
  end
end
