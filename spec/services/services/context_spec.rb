require 'spec_helper'

describe Hoodoo::Services::Context do

  before :all do
    Hoodoo::Services::Middleware.flush_services_for_test()
  end

  class RSpecTestContextImplementation < Hoodoo::Services::Implementation
  end

  class RSpecTestContextInterface < Hoodoo::Services::Interface
    interface :RSpecTestResource do
      endpoint :rspec_test_service_stub, RSpecTestContextImplementation
    end
  end

  class RSpecTestContext < Hoodoo::Services::Service
    comprised_of RSpecTestContextInterface
  end

  it 'initialises correctly' do
    ses = Hoodoo::Services::Session.new
    req = Hoodoo::Services::Request.new
    res = Hoodoo::Services::Response.new( Hoodoo::UUID.generate() )
    mid = Hoodoo::Services::Middleware.new( RSpecTestContext.new )
    int = Hoodoo::Services::Middleware::Interaction.new( {}, mid )

    con = Hoodoo::Services::Context.new( ses, req, res, int )

    expect(con.session).to eq(ses)
    expect(con.request).to eq(req)
    expect(con.response).to eq(res)
    expect(con.owning_interaction).to eq(int)
  end

  context 'reports endpoints' do
    before :each do
      ses = Hoodoo::Services::Session.new
      req = Hoodoo::Services::Request.new
      res = Hoodoo::Services::Response.new( Hoodoo::UUID.generate() )
      mid = Hoodoo::Services::Middleware.new( RSpecTestContext.new )
      int = Hoodoo::Services::Middleware::Interaction.new( {}, mid )

      @con = Hoodoo::Services::Context.new( ses, req, res, int )
    end

    shared_examples 'an endpoint' do | endpoint_method |
      it 'with the expected properties' do
        expect(@con.send(endpoint_method, :RSpecTestResource)).to be_a( Hoodoo::Services::Middleware::InterResourceLocal )
        expect(@con.send(endpoint_method, :RSpecTestResource).instance_variable_get( '@discovery_result' ) ).to be_a( Hoodoo::Services::Discovery::ForLocal )
        expect(@con.send(endpoint_method, :RSpecTestResource).instance_variable_get( '@discovery_result' ) .interface_class).to eq( RSpecTestContextInterface )
        expect(@con.send(endpoint_method, :AnotherResource)).to be_a( Hoodoo::Services::Middleware::InterResourceRemote )
        expect(@con.send(endpoint_method, :AnotherResource).instance_variable_get( '@discovery_result' ) ).to be_a( Hoodoo::Services::Discovery::ForRemote )
      end
    end

    context 'via native "#resource" and' do
      it_behaves_like 'an endpoint', :resource
    end

    context 'via alias "#endpoint" and' do
      it_behaves_like 'an endpoint', :endpoint
    end
  end
end
