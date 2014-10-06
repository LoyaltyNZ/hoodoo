require 'spec_helper'

describe ApiTools::Services::BaseMultithreadedService do

  describe '#initialize' do
    it 'should initialize with uri, name and options' do
      inst = ApiTools::Services::BaseMultithreadedService .new('TEST_URI','NAME', {:queue_options => {}})

      expect(inst.request_endpoint).to eq("NAME")
      expect(inst.response_endpoint).to eq("NAME.#{inst.endpoint_id}")
      expect(inst.queue_options).to eq({})
    end

    it 'should set default queue_options if not supplied' do
      inst = ApiTools::Services::BaseMultithreadedService .new('TEST_URI','NAME')

      expect(inst.queue_options).to eq({:exclusive => false, :auto_delete => false})
    end
  end

  describe '#send_message' do
    it 'sset reply_to and place on tx_queue' do
      inst = ApiTools::Services::BaseMultithreadedService .new('TEST_URI','NAME')

      msg = OpenStruct.new
      expect(inst.tx_queue).to receive(:<<).with(msg)

      inst.send_message(msg)

      expect(msg.reply_to).to eq(inst.response_endpoint)
    end
  end

end