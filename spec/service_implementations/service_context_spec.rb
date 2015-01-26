require 'spec_helper'

class RSpecTestServiceContextImplementation < Hoodoo::ServiceImplementation
end

class RSpecTestServiceContextInterface < Hoodoo::ServiceInterface
  interface :RSpecTestResource do
    endpoint :rspec_test_service_stub, RSpecTestServiceContextImplementation
  end
end

class RSpecTestServiceContext < Hoodoo::ServiceApplication
  comprised_of RSpecTestServiceContextInterface
end

describe Hoodoo::ServiceContext do

  it 'should initialise correctly' do
    ses = Hoodoo::ServiceSession.new
    req = Hoodoo::ServiceRequest.new
    res = Hoodoo::ServiceResponse.new( Hoodoo::UUID.generate() )
    mid = Hoodoo::ServiceMiddleware.new( RSpecTestServiceContext.new )
    con = Hoodoo::ServiceContext.new( ses, req, res, mid )

    expect(con.session).to eq(ses)
    expect(con.request).to eq(req)
    expect(con.response).to eq(res)
  end

  it 'should report endpoints' do
    ses = Hoodoo::ServiceSession.new
    req = Hoodoo::ServiceRequest.new
    res = Hoodoo::ServiceResponse.new( Hoodoo::UUID.generate() )
    mid = Hoodoo::ServiceMiddleware.new( RSpecTestServiceContext.new )
    con = Hoodoo::ServiceContext.new( ses, req, res, mid )

    expect(con.resource(:RSpecTestResource)).to be_a( Hoodoo::ServiceMiddleware::ServiceEndpoint )
    expect(con.resource(:RSpecTestResource).interface).to eq( RSpecTestServiceContextInterface )
    expect(con.resource(:AnotherResource)).to be_a( Hoodoo::ServiceMiddleware::ServiceEndpoint )
    expect(con.resource(:AnotherResource).interface).to be_nil
  end
end
