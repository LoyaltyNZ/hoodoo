require 'spec_helper'

describe ApiTools::Services::HTTPResponse do

  describe '#initialize' do
    it 'should have an piTools::Services::Response ancestor' do
      expect(ApiTools::Services::HTTPResponse <= ApiTools::Services::Response).to be(true)
    end

    it 'should call update with options queue' do
      options = { :one => 1}
      inst = ApiTools::Services::HTTPResponse.new(options)
    end
  end

  describe '#serialize' do
    it 'should set content to be a hash of instance variables' do
      options = {
        :session_id => 'one',
        :status_code => 'four',
        :headers => 'three',
        :body => 'two',
      }
      inst = ApiTools::Services::HTTPResponse.new(options)
      inst.serialize

      expect(inst.content).to eq(options)
      expect(inst.payload).to eq(options.to_msgpack)
    end
  end

  describe '#deserialize' do
    it 'should deserialize payload to content and call update' do
      options = {
        :session_id => 'one',
        :status_code => 'four',
        :headers => 'three',
        :body => 'two',
      }
      inst = ApiTools::Services::HTTPResponse.new({:payload => options.to_msgpack})
     
      expect(inst).to receive(:update).with(options)
      inst.deserialize

      expect(inst.content).to eq(options)
    end
  end

  describe '#update' do

    it 'should set instance vars from content' do

      options = {
        :session_id => 'one',
        :status_code => 'four',
        :headers => 'three',
        :body => 'two',
      }
      inst = ApiTools::Services::HTTPResponse.new

      inst.update(options)

      expect(inst.session_id).to eq('one')
      expect(inst.body).to eq('two')
      expect(inst.headers).to eq('three')
    end
  end
end