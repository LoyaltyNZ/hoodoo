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
end