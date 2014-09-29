require 'spec_helper'

describe ApiTools::Services::AMQPMessage do

  describe '#initialize' do
    it 'should initialise exchange and options' do

      inst = ApiTools::Services::AMQPMessage.new('one',{
        :routing_key => 'two',
        :type => 'three',
        :correlation_id => 'four',
        :content_type => 'five',
        :reply_to => 'six',
      })

      expect(inst.exchange).to eq('one')
      expect(inst.routing_key).to eq('two')
      expect(inst.type).to eq('three')
      expect(inst.correlation_id).to eq('four')
      expect(inst.content_type).to eq('five')
      expect(inst.reply_to).to eq('six')
    end
  end

  describe '#send_message' do
    it 'should generate a message_id' do

      pending

      mock_exchange = double
      expect(ApiTools::UUID).to receive(:generate)
      inst = ApiTools::Services::AMQPMessage.new(mock_exchange,{});
      expect(mock_exchange).to receive(:publish)
      inst.send_message
    end

    it 'should publish with the correct options' do

      pending

      mock_exchange = double
      inst = ApiTools::Services::AMQPMessage.new(mock_exchange,{
        :routing_key => 'two',
        :type => 'three',
        :correlation_id => 'four',
        :content_type => 'five',
        :reply_to => 'six',
        :payload => 'seven'
      })
      expect(mock_exchange).to receive(:publish) do |payload,options|
        expect(payload).to eq('seven')
        expect(options[:message_id]).to be_a(String)
        expect(options[:message_id].length).to eq(32)
        expect(options[:routing_key]).to eq('two')
        expect(options[:type]).to eq('three')
        expect(options[:correlation_id]).to eq('four')
        expect(options[:content_type]).to eq('five')
        expect(options[:reply_to]).to eq('six')
      end
      inst.send_message
    end
  end
end