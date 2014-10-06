require 'spec_helper'

describe ApiTools::Services::AQMPMultithreadedEndpoint do

  describe '#initialize' do
    it 'should initialize with uri and supplied options' do

      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI',
      {
        :endpoint_id => 'one',
        :request_endpoint => 'two',
        :response_endpoint => 'three',
        :timeout => 'four',
        :queue_options => 'five',

        :request_class => 'six',
        :thread_count => 'seven',
      }
      )

      expect(inst.amqp_uri).to eq('TEST_URI')
      expect(inst.endpoint_id).to eq('one')
      expect(inst.request_endpoint).to eq('two')
      expect(inst.response_endpoint).to eq('three')
      expect(inst.timeout).to eq('four')

      expect(inst.queue_options).to eq('five')
      expect(inst.request_class).to eq('six')
      expect(inst.thread_count).to eq('seven')
    end

    it 'should initialize with default options if not supplied' do

      expect(ApiTools::Services::AQMPMultithreadedEndpoint).to receive(:number_of_processors).and_return(5)
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      expect(inst.amqp_uri).to eq('TEST_URI')
      expect(inst.endpoint_id).to be_a(String)
      expect(inst.endpoint_id.length).to be(32)
      expect(inst.request_endpoint).to eq("endpoint.#{inst.endpoint_id}")
      expect(inst.response_endpoint).to eq("endpoint.#{inst.endpoint_id}.response")
      expect(inst.timeout).to eq(5000)

      expect(inst.queue_options).to eq({:exclusive => true, :auto_delete => true})
      expect(inst.request_class).to eq(ApiTools::Services::Request)
      expect(inst.thread_count).to eq(2)
    end
  end

  describe '#connect'
  describe '#close'
  describe '#process'
  describe '#create_worker_thread'
  describe '#create_rx_thread'
  describe '#create_tx_thread'
  describe '#start'
  describe '#join'
  describe '#stop'
  describe '#send_message'
  describe '#self.number_of_processors'
end