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
    ses = Hoodoo::Services::LegacySession.new
    req = Hoodoo::Services::Request.new
    res = Hoodoo::Services::Response.new( Hoodoo::UUID.generate() )
    mid = Hoodoo::Services::Middleware.new( RSpecTestContext.new )
    con = Hoodoo::Services::Context.new( ses, req, res, mid )

    expect(con.session).to eq(ses)
    expect(con.request).to eq(req)
    expect(con.response).to eq(res)
  end

  it 'should report endpoints' do
    ses = Hoodoo::Services::LegacySession.new
    req = Hoodoo::Services::Request.new
    res = Hoodoo::Services::Response.new( Hoodoo::UUID.generate() )
    mid = Hoodoo::Services::Middleware.new( RSpecTestContext.new )
    con = Hoodoo::Services::Context.new( ses, req, res, mid )

    expect(con.resource(:RSpecTestResource)).to be_a( Hoodoo::Services::Middleware::Endpoint )
    expect(con.resource(:RSpecTestResource).interface).to eq( RSpecTestContextInterface )
    expect(con.resource(:AnotherResource)).to be_a( Hoodoo::Services::Middleware::Endpoint )
    expect(con.resource(:AnotherResource).interface).to be_nil
  end
end
