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

  describe '#connect' do
    it  'should set connection to new Bunny client and start it' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      bunny = double('bunny')
      expect(bunny).to receive(:start)
      expect(Bunny).to receive(:new).with('TEST_URI').and_return(bunny)

      inst.connect
    end
  end

  describe '#close' do
    it 'should call close on connection' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      cxn = double('connection')
      expect(cxn).to receive(:close)

      inst.instance_eval { @connection = cxn }
      inst.close
    end
  end

  describe '#process' do
    it 'should throw an error' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')
      expect { inst.process(nil) }.to raise_error
    end
  end

  describe '#create_worker_thread'
  describe '#create_rx_thread'
  describe '#create_tx_thread'
  describe '#start'

  describe '#join' do
    it 'should call join on rx_thread' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      rxth = double('tx_thread')
      expect(rxth).to receive(:join)

      inst.instance_eval { @rx_thread = rxth }
      inst.join
    end
  end

  describe '#stop'

  describe '#send_message' do
    it 'should push msg on tx_queue' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      msg = double('message')
      txq = double('tx_queue')
      expect(txq).to receive(:<<).with(msg)

      inst.instance_eval { @tx_queue = txq }
      inst.send_message(msg)
    end
  end

  describe '#self.number_of_processors'
end