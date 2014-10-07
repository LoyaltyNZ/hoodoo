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

  describe '#create_worker_thread' do
    it 'should create and return a new thread, which pops rx_queue and calls process' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      expect(Thread).to receive(:new) do |&block|

        expect(inst.rx_queue).to receive(:pop).and_return(123781273)
        expect(inst).to receive(:process).with(123781273) do
          raise Interrupt
        end
        inst.instance_eval(&block)
      end.and_return(2381712873)

      expect(inst.create_worker_thread).to eq(2381712873)
    end

    it 'should create thread which places response on tx_queue if it is the correct type' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      expect(Thread).to receive(:new) do |&block|

        resp = ApiTools::Services::Response.new
        expect(inst.rx_queue).to receive(:pop).and_return(123781273)
        expect(inst).to receive(:process).with(123781273).and_return(resp)
        expect(inst.tx_queue).to receive(:<<) do |rmsg|
          expect(rmsg).to be(resp)
          raise Interrupt
        end
        inst.instance_eval(&block)
      end.and_return(2381712873)

      expect(inst.create_worker_thread).to eq(2381712873)
    end

    it 'should create thread which logs error on failure and continues' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      expect(Thread).to receive(:new) do |&block|
        ex = RuntimeError.new('one')
        expect(inst.rx_queue).to receive(:pop).and_return(123781273)
        expect(ApiTools::Logger).to receive(:error)
        expect(inst).to receive(:process) do |rmsg|
          raise ex
        end
        # Checks if pop is called again (continue loop), now exit
        expect(inst.rx_queue).to receive(:pop) { raise Interrupt }
        inst.instance_eval(&block)
      end

      inst.create_worker_thread
    end
  end

  describe '#create_rx_thread' do
    it 'should create thread and set rx_thread and rx_channel' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      channel = double('channel')
      queue = double('queue')
      expect(channel).to receive(:queue).and_return(queue)
      expect(channel).to receive(:prefetch).with(1)
      expect(queue).to receive(:subscribe) { raise Interrupt }

      expect(Thread).to receive(:new) do |&block|
        expect(inst.connection).to receive(:create_channel).and_return(channel)

        inst.instance_eval(&block)
      end.and_return(:rx_thread)

      inst.create_rx_thread
      expect(inst.rx_thread).to eq(:rx_thread)
    end

    it 'should create thread that enqueues correct messages' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      channel = double('channel')
      queue = double('queue')
      expect(channel).to receive(:queue).and_return(queue)
      expect(channel).to receive(:prefetch).with(1)
      expect(queue).to receive(:subscribe) do |options, &block|
        expect(options).to eq(:ack => true, :block => true)

        di = OpenStruct.new(:delivery_tag => :di_tag)

        expect(inst.request_class).to receive(:create_from_raw_message)
        .with(di,:mt,:pl)
        .and_return(:rawmsg)
        expect(inst.rx_queue).to receive(:<<).with(:rawmsg)

        expect(inst.rx_channel).to receive(:ack).with(:di_tag) { raise Interrupt }
        block.call(di,:mt,:pl)
      end

      expect(Thread).to receive(:new) do |&block|
        expect(inst.connection).to receive(:create_channel).and_return(channel)
        inst.instance_eval(&block)
      end

      inst.create_rx_thread
    end

    it 'should create thread which logs error on failure and continues' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      channel = double('channel')
      queue = double('queue')
      ex = RuntimeError.new('one')
      expect(channel).to receive(:queue).and_return(queue)
      expect(channel).to receive(:prefetch).with(1)

      expect(ApiTools::Logger).to receive(:error).with(ex)

      expect(queue).to receive(:subscribe) { raise ex }

      expect(Thread).to receive(:new) do |&block|
        expect(inst.connection).to receive(:create_channel).and_return(channel)

        # Checks if loop continues and exits
        expect(queue).to receive(:subscribe) { raise Interrupt }
        inst.instance_eval(&block)
      end

      inst.create_rx_thread
    end
  end

  describe '#create_tx_thread'

  describe '#start' do
    it 'should clear the boot queue, connect and create rx and tx threads' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      expect(inst.boot_queue).to receive(:clear)
      expect(inst).to receive(:connect)
      expect(inst).to receive(:create_tx_thread)
      expect(inst).to receive(:create_rx_thread)

      inst.thread_count = 0

      inst.boot_queue << true
      inst.boot_queue << true

      inst.start
    end

    it 'should create and store thread_count worker threads' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      expect(inst.boot_queue).to receive(:clear)
      expect(inst).to receive(:connect)
      expect(inst).to receive(:create_tx_thread)
      expect(inst).to receive(:create_rx_thread)

      inst.thread_count = 3
      expect(inst).to receive(:create_worker_thread).and_return(1)
      expect(inst).to receive(:create_worker_thread).and_return(2)
      expect(inst).to receive(:create_worker_thread).and_return(3)

      inst.boot_queue << true
      inst.boot_queue << true

      inst.start

      expect(inst.worker_threads).to eq([1,2,3])
    end

    it 'should timeout if rx and tx threads dont push onto boot_queue' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      expect(inst.boot_queue).to receive(:clear)
      expect(inst).to receive(:connect)
      expect(inst).to receive(:create_tx_thread)
      expect(inst).to receive(:create_rx_thread)

      inst.thread_count = 0
      inst.timeout = 1

      expect { inst.start }.to raise_error(RuntimeError)
    end
  end

  describe '#join' do
    it 'should call join on rx_thread' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      rxth = double('tx_thread')
      expect(rxth).to receive(:join)

      inst.instance_eval { @rx_thread = rxth }
      inst.join
    end
  end

  describe '#stop' do

    it 'should kill tx_thread and tx_thread' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      rxt = double('rx_thread')
      txt = double('tx_thread')
      inst.instance_eval do
        @rx_thread = rxt
        @tx_thread = txt
      end

      expect(rxt).to receive(:kill)
      expect(txt).to receive(:kill)

      inst.stop
    end

    it 'should kill all worker threads' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      wht = [double('worker_thread_1'),double('worker_thread_2')]

      expect(wht[0]).to receive(:kill)
      expect(wht[1]).to receive(:kill)

      inst.instance_eval do
        @worker_threads = wht
      end

      inst.stop
    end

    it 'should set rx_thread, tx_thread to nil and worker_threads to []' do
      inst = ApiTools::Services::AQMPMultithreadedEndpoint.new('TEST_URI')

      rxt = double('rx_thread')
      txt = double('tx_thread')
      wht = [double('worker_thread')]

      expect(rxt).to receive(:kill)
      expect(txt).to receive(:kill)
      expect(wht[0]).to receive(:kill)


      inst.instance_eval do
        @rx_thread = rxt
        @tx_thread = txt
        @worker_threads = wht
      end

      inst.stop

      expect(inst.rx_thread).to be_nil
      expect(inst.tx_thread).to be_nil
      expect(inst.worker_threads).to eq([])
    end
  end

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