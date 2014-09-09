require 'spec_helper'

describe ApiTools::Services::BaseService do

  describe '#initialize' do

    it 'should initialize correctly' do
      instance = ApiTools::Services::BaseService.new('one','two',{:timeout => 200})

      expect(instance.amqp_uri).to eq('one')
      expect(instance.listener_endpoint).to eq('service.two')
      expect(instance.response_endpoint).to eq("service.two.#{instance.service_instance_id}")
      expect(instance.requests).to be_a(ApiTools::ThreadSafeHash)
      expect(instance.service_instance_id).to be_a(String)
      expect(instance.service_instance_id.length).to eq(32)
      expect(instance.timeout).to eq(200)
    end

    it 'should default timeout to 5000' do
      instance = ApiTools::Services::BaseService.new('one','two')
      expect(instance.timeout).to eq(5000)
    end
  end

  describe '#instance_id' do
    it 'should return instance service_instance_id' do
      instance = ApiTools::Services::BaseService.new('one','two')

      expect(instance.instance_id).to eq(instance.service_instance_id)
      instance.service_instance_id = 'ascinasic'

      expect(instance.instance_id).to eq('ascinasic')
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

  describe '#start' do
    it 'should create and run request and response threads' do
      instance = ApiTools::Services::BaseService.new('one','two')
      mock_request_thread = double()
      mock_response_thread = double()

      expect(instance).to receive(:create_request_thread) do |queue|
        expect(queue).to be_a(Queue)
        queue << true
        mock_request_thread
      end

      expect(instance).to receive(:create_response_thread)do |queue|
        expect(queue).to be_a(Queue)
        queue << true
        mock_response_thread
      end

      expect(mock_request_thread).to receive(:run)
      expect(mock_response_thread).to receive(:run)

      instance.start
    end
  end

  describe '#join' do
    it 'should call join on the request thread' do
      instance = ApiTools::Services::BaseService.new('one','two')
      mock_thread = double()

      instance.request_thread = mock_thread

      expect(mock_thread).to receive(:join)

      instance.join
    end
  end

  describe '#stop' do
    it 'should call terminate on the request and response threads' do
      instance = ApiTools::Services::BaseService.new('one','two')
      mock_request_thread = double()
      mock_response_thread = double()

      instance.response_thread = mock_request_thread
      instance.request_thread = mock_response_thread

      expect(mock_request_thread).to receive(:terminate)
      expect(mock_response_thread).to receive(:terminate)

      instance.stop
    end
  end
end