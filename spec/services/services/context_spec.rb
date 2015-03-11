require 'spec_helper'

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

describe Hoodoo::Services::Context do

  it 'should initialise correctly' do
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

  it 'should report endpoints' do
    ses = Hoodoo::Services::Session.new
    req = Hoodoo::Services::Request.new
    res = Hoodoo::Services::Response.new( Hoodoo::UUID.generate() )
    mid = Hoodoo::Services::Middleware.new( RSpecTestContext.new )
    int = Hoodoo::Services::Middleware::Interaction.new( {}, mid )

    con = Hoodoo::Services::Context.new( ses, req, res, int )

    expect(con.resource(:RSpecTestResource)).to be_a( Hoodoo::Services::Middleware::InterResourceLocal )
    expect(con.resource(:RSpecTestResource).discovery_result).to be_a( Hoodoo::Services::Discovery::ForLocal )
    expect(con.resource(:RSpecTestResource).discovery_result.interface_class).to eq( RSpecTestContextInterface )
    expect(con.resource(:AnotherResource)).to be_a( Hoodoo::Services::Middleware::InterResourceRemote )
    expect(con.resource(:AnotherResource).discovery_result).to be_a( Hoodoo::Services::Discovery::ForRemote )
  end
end
