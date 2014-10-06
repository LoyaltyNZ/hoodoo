require 'spec_helper'

describe ApiTools::Services::BaseClient do

  describe '#initialize' do
    it 'should initialize response_endpoint' do
      instance = ApiTools::Services::BaseClient.new('one')

      expect(instance.amqp_uri).to eq('one')
      expect(instance.response_endpoint).to eq('client.'+instance.endpoint_id)
    end
  end
end