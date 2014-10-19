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
    it 'should call Thread.new' do

      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',{})

      connection = double('connection')
      channel = double('channel')
      queue = double('queue')
      exchange = double('exchange')

      expect(queue).to receive(:subscribe) do |options, &block|
        expect(options).to eq(:block=>true)

        expect(inst.requests).to receive(:has_key?).with('098345234234').and_return(true)

        delivery_info = OpenStruct.new({
          :routing_key => 'one',
        })
        metadata = OpenStruct.new({
          :message_id => 'two',
          :type => 'three',
          :correlation_id => '098345234234',
          :reply_to => 'five',
          :content_type => 'six',
          :received_by => 'seven',
        })
        payload = 'PAYLOAD'

        expect(inst.response_class).to receive(:new).with(exchange, {
          :message_id => metadata.message_id,
          :type => metadata.type,
          :correlation_id => metadata.correlation_id,
          :reply_to => metadata.reply_to,
          :content_type => metadata.content_type,
          :received_by => delivery_info.routing_key,
          :payload => payload,
        }).and_return(23498234987)

        inst.instance_eval {
          block.call(delivery_info, metadata, payload)
        }

        # Break Thread Runloop.
        raise Error
      end

      expect(channel).to receive(:default_exchange).and_return(exchange)

      expect(channel).to receive(:queue).with(inst.response_endpoint, {
        :exclusive => true,
        :auto_delete => true,
      }).and_return(queue)

      expect(connection).to receive(:start)
      expect(connection).to receive(:create_channel).and_return(channel)

      expect(Bunny).to receive(:new).with('TEST_URI').and_return(connection)

      expect(Thread).to receive(:new) do |&block|

        block.call
      end

      inst.create_response_thread

      expect(inst.exchange).to be(exchange)

    end
  end

  describe '#start' do
    it 'should clear boot queue, create thread, run and wait for boot queue pop' do
      boot_queue = double('boot_queue')
      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',{})
      inst.response_thread = double('response_thread')

      inst.instance_eval { @boot_queue = boot_queue }

      expect(boot_queue).to receive(:clear)
      expect(inst).to receive(:create_response_thread).and_return(inst.response_thread)
      expect(inst.response_thread).to receive(:run)
      expect(boot_queue).to receive(:pop).and_return(true)

      inst.start
    end

    it 'should raise RuntimeError if boot queue comes back false' do
      boot_queue = double('boot_queue')
      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',{})
      inst.response_thread = double('response_thread')

      inst.instance_eval { @boot_queue = boot_queue }

      expect(boot_queue).to receive(:clear)
      expect(inst).to receive(:create_response_thread).and_return(inst.response_thread)
      expect(inst.response_thread).to receive(:run)
      expect(boot_queue).to receive(:pop).and_return(false)

      expect {
        inst.start
      }.to raise_error(RuntimeError)
    end
  end

  describe '#join' do
    it 'should call join on response_thread' do
      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',{})
      inst.response_thread = double('response_thread')

      expect(inst.response_thread).to receive(:join)
      inst.join
    end
  end

  describe '#request' do
    it 'should call new on request class with correct options' do
      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',{})
      inst.request_class = double('request_class')

      expect(inst.request_class).to receive(:new).with({
        :routing_key => 'test.queue',
        :type => 'request'
      }).and_return(234923498)
      expect(inst).to receive(:send_sync_request).with(234923498)
      inst.request('test.queue',{})
    end
  end

  describe '#send_async_request' do
    it 'should set reply_to, call send_message, set requests for id, and return request' do

      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',{})

      request = OpenStruct.new({
        :message_id => 'one',
        :reply_to => nil,
      })

      expect(inst).to receive(:send_message).with(inst.exchange, request)

      inst.send_async_request(request)

      expect(inst.requests[request.message_id]).to be(request)
    end

    it 'should set timeout false on request' do
      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',{})

      request = OpenStruct.new({
        :message_id => 'one',
        :reply_to => nil,
        :timeout => 'cbaiscnasc',
      })

      expect(inst).to receive(:send_message).with(inst.exchange, request)

      inst.send_async_request(request)

      expect(request.timeout).to be(false)
    end
  end

  describe '#send_sync_request' do
    it 'should call send_async_request' do
      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',{})

      inst.timeout = 61235

      request = OpenStruct.new({
        :message_id => 'one',
        :reply_to => nil,
        :queue => Queue.new,
      })

      response = OpenStruct.new

      expect(inst).to receive(:send_async_request) do
        request.queue << response
      end

      expect(Timeout).to receive(:timeout) do |timeout, &block|
        expect(timeout).to eq(61.235)
        block.call
      end

      expect(inst.requests).to receive(:delete).with('one')

      expect(inst.send_sync_request(request)).to be(response)
    end

    it 'should timeout if no response' do
      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',{})

      inst.timeout = 10

      request = OpenStruct.new({
        :message_id => 'one',
        :reply_to => nil,
        :queue => Queue.new,
      })

      response = OpenStruct.new

      expect(inst).to receive(:send_async_request)

      expect(inst.requests).to receive(:delete).with('one')

      expect(inst.send_sync_request(request)).to be(nil)
      expect(request.timeout).to be(true)
    end
  end

  describe '#send_message' do

    it 'should generate options, serialize and call exchange.publish' do
      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',{})

      exchange = double('exchange')
      options = {
        :message_id => 'one',
        :routing_key => 'two',
        :type => 'three',
        :correlation_id => 'four',
        :content_type => 'five',
        :reply_to => 'six',
      }
      msg = OpenStruct.new(options.merge({ :payload => "PAYLOAD" }))

      expect(msg).to receive(:serialize)

      expect(exchange).to receive(:publish).with('PAYLOAD', options)

      inst.send_message(exchange, msg)
    end
  end

  describe '#stop' do
    it 'should call terminate on response_thread' do
      inst = ApiTools::Services::AQMPEndpoint.new('TEST_URI',{})
      inst.response_thread = double('response_thread')

      expect(inst.response_thread).to receive(:terminate)
      inst.stop
    end
  end
end