require 'spec_helper'

describe ApiTools::Services::AMQPMessage do

  describe '#initialize' do
    it 'should initialize with options' do

      inst = ApiTools::Services::AMQPMessage.new(
      :message_id => 'one',
      :routing_key => 'two',
      :correlation_id => 'three',
      :reply_to => 'four',
      :type => 'five',
      :content_type => 'six',
      :received_by => 'seven',
      )

      expect(inst.message_id).to eq('one')
      expect(inst.routing_key).to eq('two')
      expect(inst.correlation_id).to eq('three')
      expect(inst.reply_to).to eq('four')
      expect(inst.type).to eq('five')
      expect(inst.content_type).to eq('six')
      expect(inst.received_by).to eq('seven')
    end

    it 'should generate id if not supplied' do

      inst = ApiTools::Services::AMQPMessage.new

      expect(inst.message_id).not_to be_nil
      expect(inst.message_id.length).to be(32)
    end

    it 'should set type=other if not supplied' do
      inst = ApiTools::Services::AMQPMessage.new
      expect(inst.type).to eq('other')
    end

    it 'should set content_type=application/octet-stream if not supplied' do
      inst = ApiTools::Services::AMQPMessage.new
      expect(inst.content_type).to eq('application/octet-stream')
    end

    it 'should deserialize if payload not nil' do

      content = {:one => 1}
      inst = ApiTools::Services::AMQPMessage.new(
      :payload => content.to_msgpack
      )

      expect(inst.content).to eq(content)
    end
  end

  describe '#serialize' do
    it 'should set payload to msgpack of content' do

      content = double(content)

      expect(content).to receive(:to_msgpack).and_return(234723)

      inst = ApiTools::Services::AMQPMessage.new

      inst.content = content
      inst.serialize

      expect(inst.payload).to eq(234723)
    end
  end

  describe '#deserialize' do
    it 'should set content to MessagePack.unpack of payload' do
      payload = { :five => 2 }

      expect(MessagePack).to receive(:unpack).with(payload, :symbolize_keys => true).and_return(823674234)

      inst = ApiTools::Services::AMQPMessage.new

      inst.payload = payload
      inst.deserialize

      expect(inst.content).to eq(823674234)
    end
  end

  describe '#self.create_from_raw_message' do

    it 'should construct an instance with the correct params' do

      data = {:ten => 10}

      metadata = OpenStruct.new(
        :message_id => 'one',
        :type => 'two',
        :correlation_id => 'three',
        :reply_to => 'four',
        :content_type => 'five',
      )

      delivery_info = OpenStruct.new(
        :routing_key => 'six',
      )

      expect(ApiTools::Services::AMQPMessage).to receive(:new).with(
        :message_id => 'one',
        :type => 'two',
        :correlation_id => 'three',
        :reply_to => 'four',
        :content_type => 'five',
        :received_by => 'six',
        :payload => data.to_msgpack
      ).and_call_original

      inst = ApiTools::Services::AMQPMessage.create_from_raw_message(delivery_info, metadata, data.to_msgpack)

      expect(inst.content).to eq(data)

    end
  end
end