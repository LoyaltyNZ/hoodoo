require 'spec_helper'

describe ApiTools::Services::Request do

  describe '#initialize' do
    it 'should have an AMQPMessage ancestor' do
      expect(ApiTools::Services::Response <= ApiTools::Services::AMQPMessage).to be(true)
    end

    it 'should have correct type if not defined' do
      inst = ApiTools::Services::Response.new({})
      expect(inst.type).to eq('response')
    end
  end
end