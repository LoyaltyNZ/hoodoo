require 'spec_helper'

describe ApiTools::Services::HTTPRequest do

  describe '#initialize' do
    it 'should have an piTools::Services::Response ancestor' do
      expect(ApiTools::Services::HTTPResponse <= ApiTools::Services::Response).to be(true)
    end

    it 'should call update with options queue' do
      options = { :one => 1}
      inst = ApiTools::Services::HTTPRequest.new(options)
    end
  end

  describe '#serialize' do
    it 'should set content to be a hash of instance variables' do
      options = {
        :session_id => 'one',
        :scheme => 'two',
        :host => 'three',
        :port => 'four',
        :path => 'five',
        :query => 'six',
        :verb => 'seven',
        :headers => 'eight',
        :body => 'nine',
      }
      inst = ApiTools::Services::HTTPRequest.new(options)
      inst.serialize

      expect(inst.content).to eq(options)
      expect(inst.payload).to eq(options.to_msgpack)
    end
  end

  describe '#deserialize' do
    it 'should deserialize payload to content and call update' do
      options = {
        :session_id => 'one',
        :scheme => 'two',
      }
      inst = ApiTools::Services::HTTPRequest.new({:payload => options.to_msgpack})
     
      expect(inst).to receive(:update).with(options)
      inst.deserialize

      expect(inst.content).to eq(options)
    end
  end

  describe '#update' do

    it 'should set instance vars from content' do

      options = {
        :session_id => 'one',
        :scheme => 'two',
        :host => 'three',
        :port => 'four',
        :path => 'five',
        :query => 'six',
        :verb => 'seven',
        :headers => 'eight',
        :body => 'nine',
      }
      inst = ApiTools::Services::HTTPRequest.new

      inst.update(options)

      expect(inst.session_id).to eq('one')
      expect(inst.scheme).to eq('two')
      expect(inst.host).to eq('three')
      expect(inst.port).to eq('four')
      expect(inst.path).to eq('five')
      expect(inst.query).to eq('six')
      expect(inst.verb).to eq('seven')
      expect(inst.headers).to eq('eight')
      expect(inst.body).to eq('nine')
    end
  end
end