require 'spec_helper'

describe ApiTools::Services::BaseClient do

  describe '#initialize' do
    it 'should initialise amqp_uri, client_id, response_endpoint and requests' do

      instance = ApiTools::Services::BaseClient.new('one')

      expect(instance.amqp_uri).to eq('one')
      expect(instance.client_id).to be_a(String)
      expect(instance.client_id.length).to eq(32)
      expect(instance.response_endpoint).to eq('client.'+instance.client_id)
      expect(instance.requests).to be_a(ApiTools::ThreadSafeHash)
    end
  end

  describe '#create_listener_thread' do
    it 'should create and return a thread' do
      instance = ApiTools::Services::BaseClient.new('one')
      expect(Thread).to receive(:new) do |&block|
        'thread'
      end

      expect(instance.create_listener_thread(nil)).to eq('thread')
    end

    it 'should create, start and process a response correctly' do
      instance = ApiTools::Services::BaseClient.new('one')

      mock_bunny = double()
      mock_channel = double()
      mock_queue = double()

      expect(Bunny).to receive(:new).with('one').and_return(mock_bunny)
      expect(mock_bunny).to receive(:start)
      expect(mock_bunny).to receive(:create_channel).and_return(mock_channel)
      expect(mock_channel).to receive(:queue).with(instance.response_endpoint, {
        :exclusive => true,
        :auto_delete => true,
      }).and_return(mock_queue)

      request_queue = Queue.new
      instance.requests = {
        '23423874' => {
          :queue => request_queue
        }
      }

      expect(mock_queue).to receive(:subscribe) do |options, &block|
        expect(options).to eq({:block=>true})
        block.call(nil, {:correlation_id => '23423874', :type=>"response"}, '{"data":"five"}')
        break
      end


      wait_queue = Queue.new
      expect(wait_queue).to receive(:<<).with(true).and_call_original

      thread = instance.create_listener_thread(wait_queue)

      expect(wait_queue.pop).to eq(true)
      expect(request_queue.pop).to eq({:type=>"response", :data=>{:data=>"five"}})

      thread.kill
    end

    it 'should ignore non-response packets' do
      instance = ApiTools::Services::BaseClient.new('one')

      mock_bunny = double()
      mock_channel = double()
      mock_queue = double()

      expect(Bunny).to receive(:new).with('one').and_return(mock_bunny)
      expect(mock_bunny).to receive(:start)
      expect(mock_bunny).to receive(:create_channel).and_return(mock_channel)
      expect(mock_channel).to receive(:queue).with(instance.response_endpoint, {
        :exclusive => true,
        :auto_delete => true,
      }).and_return(mock_queue)

      request_queue = Queue.new
      instance.requests = {
        '23423874' => {
          :queue => request_queue
        }
      }

      expect(mock_queue).to receive(:subscribe) do |options, &block|
        expect(options).to eq({:block=>true})

        expect(request_queue).not_to receive(:<<)
        block.call(nil, {:correlation_id => '23423874', :type=>"other"}, '{"data":"five"}')
        break
      end


      wait_queue = Queue.new
      expect(wait_queue).to receive(:<<).with(true).and_call_original

      thread = instance.create_listener_thread(wait_queue)

      expect(wait_queue.pop).to eq(true)
      expect(request_queue.length).to eq(0)

      thread.kill
    end
  end

  describe '#start' do
    it 'should create a bunny connection and set channel and exchange' do

      instance = ApiTools::Services::BaseClient.new('one')

      mock_bunny = double()
      mock_channel = double()
      mock_listener = double()

      expect(Bunny).to receive(:new).with('one').and_return(mock_bunny)
      expect(mock_bunny).to receive(:start)
      expect(mock_bunny).to receive(:create_channel).and_return(mock_channel)
      expect(mock_channel).to receive(:default_exchange).and_return('exchange')

      expect(instance).to receive(:create_listener_thread) do |queue|
        queue << true
      end.and_return(mock_listener)
      expect(mock_listener).to receive(:run)

      instance.start

      expect(instance.connection).to eq(mock_bunny)
      expect(instance.channel).to eq(mock_channel)
      expect(instance.exchange).to eq('exchange')
    end
  end

  describe '#request' do
    it 'should call exchange.publish with the correct params' do

      instance = ApiTools::Services::BaseClient.new('one')
      instance.exchange = double()

      expect(instance.exchange).to receive(:publish) do |data, options|
        expect(data).to eq('{"data":"one"}')
        expect(options[:message_id]).to be_a(String)
        expect(options[:message_id].length).to eq(32)
        expect(options[:routing_key]).to eq('service.name')
        expect(options[:reply_to]).to eq(instance.response_endpoint)
        expect(options[:content_type]).to eq('application/json; charset=utf-8')
      end

      mock_queue = double()
      expect(mock_queue).to receive(:pop).and_return(true)

      expect(Queue).to receive(:new).and_return mock_queue

      instance.request('service.name',{ :data=>"one" })
    end

    it 'should timeout properly' do

      instance = ApiTools::Services::BaseClient.new('one')
      instance.exchange = double()

      expect(instance.exchange).to receive(:publish) do |data, options|
        expect(data).to eq('{"data":"one"}')
        expect(options[:message_id]).to be_a(String)
        expect(options[:message_id].length).to eq(32)
        expect(options[:routing_key]).to eq('service.name')
        expect(options[:reply_to]).to eq(instance.response_endpoint)
        expect(options[:content_type]).to eq('application/json; charset=utf-8')
      end

      mock_queue = double()
      expect(mock_queue).to receive(:pop) do
        raise TimeoutError
      end

      expect(Queue).to receive(:new).and_return mock_queue

      instance.request('service.name',{ :data=>"one" })
    end
  end
end