require 'spec_helper'

describe ApiTools::Services::Request do

  describe '#initialize' do
    it 'should have an AMQPMessage ancestor' do
      expect(ApiTools::Services::Request <= ApiTools::Services::AMQPMessage).to be(true)
    end

    it 'should initialise queue' do
      inst = ApiTools::Services::Request.new({})
      expect(inst.queue).to be_a(Queue)
    end

    it 'should have correct type if not defined' do
      inst = ApiTools::Services::Request.new({})
      expect(inst.type).to eq('request')
    end
  end

  describe '#create_response' do
    it 'should return a new ApiTools::Services::Response' do
      inst = ApiTools::Services::Request.new({})

      expect(inst.create_response).to be_a(ApiTools::Services::Response)
    end

    it 'should create new response with correct params' do

      msg_options ={
        :message_id => 'two',
        :reply_to => 'three',
      }
      inst = ApiTools::Services::Request.new(msg_options)

      expect(ApiTools::Services::Response).to receive(:new) do |options|
        expect(options).to eq( {
          :routing_key=>"three", :correlation_id=>"two", :type=>"response"
        })
      end

      inst.create_response
    end

    it 'should merge supplied options after set defaults' do


      inst = ApiTools::Services::Request.new({
        :message_id => 'two'
      })

      expect(ApiTools::Services::Response).to receive(:new) do |options|
        expect(options[:correlation_id]).to eq('two')
        expect(options[:type]).to eq('error')
      end

      inst.create_response({
        :type => 'error'
      })
    end
  end

  describe '#is_async?' do
    it 'should return @is_async' do

      inst = ApiTools::Services::Request.new({})

      inst.is_async = true
      expect(inst.is_async?).to be(true)

      inst.is_async = false
      expect(inst.is_async?).to be(false)
    end
  end

  describe '#timeout?' do
    it 'should return @timeout' do

      inst = ApiTools::Services::Request.new({})

      inst.timeout = true
      expect(inst.timeout?).to be(true)

      inst.timeout = false
      expect(inst.timeout?).to be(false)
    end
  end
end