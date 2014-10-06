require 'spec_helper'

describe ApiTools::Services::AQMPEndpoint do

  describe '#initialize' do
    it 'should initialize with uri and options' do
      expect(Queue).to receive(:new)

      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',
      {
        :timeout => 12352,
        :request_class => 555,
        :response_class => 666,
      }
      )

      expect(inst.amqp_uri).to eq('TEST_URI')
      expect(inst.timeout).to eq(12352)

      expect(inst.endpoint_id).not_to be_nil
      expect(inst.endpoint_id.length).to be(32)
      expect(inst.response_endpoint).to eq("endpoint.#{inst.endpoint_id}")

      expect(inst.request_class).to eq(555)
      expect(inst.response_class).to eq(666)
    end

    it 'should set request_class and response_class to defaults if not supplied ' do

      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',
      {
        :timeout => 12352
      }
      )

      expect(inst.request_class).to be(ApiTools::Services::Request)
      expect(inst.response_class).to be(ApiTools::Services::Response)
    end
  end

  describe '#create_response_thread' do

  end

  describe '#start' do
  end

  describe '#join' do
  end

  describe '#request' do
  end

  describe '#send_async_request' do
  end

  describe '#send_sync_request' do
  end

  describe '#send_message' do
  end

  describe '#stop' do
  end
end