require 'spec_helper.rb'

describe ApiTools::ServiceMiddleware::AMQPLogMessage do

  require 'msgpack'

  let(:hash) do
    {
      :id => '1',
      :level => :info,
      :component => :RSpec,
      :code => 'hello',
      :data => { 'this' => 'that' },
      :client_id => '2',
      :interaction_id => '3',
      :participant_id => '4',
      :outlet_id => '5'
    }
  end

  it 'serializes' do
    obj = described_class.new( hash )
    expect( obj.serialize ).to eq( MessagePack.pack( hash ) )
  end

  it 'deserializes' do
    obj = described_class.new( hash )
    expect( obj.serialize ).to eq( MessagePack.pack( hash ) )
    obj.id = nil # Clear some instance vars
    obj.level = nil
    obj.deserialize # Should reset instance vars based on prior serialization
    expect( obj.serialize ).to eq( MessagePack.pack( hash ) )
  end
end
