require 'spec_helper'

describe ApiTools::Services::BaseService do

  describe '#initialize' do

    it 'should initialize correctly' do
      instance = ApiTools::Services::BaseService.new('one','two',{:timeout => 200})

      expect(instance.amqp_uri).to eq('one')
      expect(instance.listener_endpoint).to eq('service.two')
      expect(instance.response_endpoint).to eq("service.two.#{instance.endpoint_id}")
      expect(instance.requests).to be_a(ApiTools::ThreadSafeHash)
      expect(instance.endpoint_id).to be_a(String)
      expect(instance.endpoint_id.length).to eq(32)
      expect(instance.timeout).to eq(200)
    end

    it 'should default timeout to 5000' do
      instance = ApiTools::Services::BaseService.new('one','two')
      expect(instance.timeout).to eq(5000)
    end
  end

  describe '#endpoint_id' do
    it 'should return instance endpoint_id' do
      instance = ApiTools::Services::BaseService.new('one','two')

      expect(instance.endpoint_id).to eq(instance.endpoint_id)
      instance.endpoint_id = 'ascinasic'

      expect(instance.endpoint_id).to eq('ascinasic')
    end
  end

  describe '#process' do
    it 'should raise an error.' do
      instance = ApiTools::Services::BaseService.new('one','two')
      expect{instance.process('one','two','three')}.to raise_error
    end
  end

  describe '#respond' do
    it 'should call publish on exchange with correct params' do
      instance = ApiTools::Services::BaseService.new('one','two')

      mock_exchange = double()

      expect(mock_exchange).to receive(:publish) do |data, options|
        expect(data).to eq('{"data":1}')
        expect(options[:message_id]).to be_a(String)
        expect(options[:message_id].length).to eq(32)
        expect(options[:routing_key]).to eq('one')
        expect(options[:type]).to eq('two')
        expect(options[:correlation_id]).to eq('three')
        expect(options[:content_type]).to eq('application/json; charset=utf-8')
      end

      instance.respond(mock_exchange, 'one', 'three', 'two', {:data=>1})
    end
  end

   describe '#create_response_thread' do
    it 'should create and return a thread' do
      instance = ApiTools::Services::BaseService.new('one','two')
      expect(Thread).to receive(:new) do |&block|
        'thread'
      end

      expect(instance.create_response_thread(nil)).to eq('thread')
    end

    it 'should create, start and process a response correctly' do
      instance = ApiTools::Services::BaseService.new('one','two')

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

      thread = instance.create_response_thread(wait_queue)

      expect(wait_queue.pop).to eq(true)
      expect(request_queue.pop).to eq({:type=>"response", :data=>{:data=>"five"}})

      thread.kill
    end

    it 'should ignore non-response packets' do
      instance = ApiTools::Services::BaseService.new('one','two')

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

      thread = instance.create_response_thread(wait_queue)

      expect(wait_queue.pop).to eq(true)
      expect(request_queue.length).to eq(0)

    end
  end

  describe '#start' do
    it 'should create and run request and response threads' do
      instance = ApiTools::Services::BaseService.new('one','two')
      mock_service_thread = double()
      mock_response_thread = double()

      expect(instance).to receive(:create_service_thread) do |queue|
        expect(queue).to be_a(Queue)
        queue << true
        mock_service_thread
      end

      expect(instance).to receive(:create_response_thread)do |queue|
        expect(queue).to be_a(Queue)
        queue << true
        mock_response_thread
      end

      expect(mock_service_thread).to receive(:run)
      expect(mock_response_thread).to receive(:run)

      instance.start
    end
  end

  describe '#join' do
    it 'should call join on the request thread' do
      instance = ApiTools::Services::BaseService.new('one','two')
      mock_thread = double()

      instance.service_thread = mock_thread

      expect(mock_thread).to receive(:join)

      instance.join
    end
  end

  describe '#stop' do
    it 'should call terminate on the request and response threads' do
      instance = ApiTools::Services::BaseService.new('one','two')
      mock_service_thread = double()
      mock_response_thread = double()

      instance.response_thread = mock_service_thread
      instance.service_thread = mock_response_thread

      expect(mock_service_thread).to receive(:terminate)
      expect(mock_response_thread).to receive(:terminate)

      instance.stop
    end
  end
end