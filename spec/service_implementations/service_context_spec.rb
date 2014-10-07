require 'spec_helper'

class RSpecTestServiceContextImplementation < ApiTools::ServiceImplementation
end

class RSpecTestServiceContextInterface < ApiTools::ServiceInterface
  interface :RSpecTestResource do
    endpoint :rspec_test_service_stub, RSpecTestServiceContextImplementation
  end
end

class RSpecTestServiceContext < ApiTools::ServiceApplication
  comprised_of RSpecTestServiceContextInterface
end

describe ApiTools::ServiceContext do

  it 'should initialise correctly' do
    ses = ApiTools::ServiceSession.new
    req = ApiTools::ServiceRequest.new
    res = ApiTools::ServiceResponse.new
    mid = ApiTools::ServiceMiddleware.new( RSpecTestServiceContext.new )
    con = ApiTools::ServiceContext.new( ses, req, res, mid )

    expect(con.session).to eq(ses)
    expect(con.request).to eq(req)
    expect(con.response).to eq(res)
  end

  it 'should initialise report endpoints' do
    ses = ApiTools::ServiceSession.new
    req = ApiTools::ServiceRequest.new
    res = ApiTools::ServiceResponse.new
    mid = ApiTools::ServiceMiddleware.new( RSpecTestServiceContext.new )
    con = ApiTools::ServiceContext.new( ses, req, res, mid )

    expect(con.resource(:RSpecTestResource)).to be_a( ApiTools::ServiceMiddleware::ServiceEndpoint )
    expect(con.resource(:RSpecTestResource).interface).to eq( RSpecTestServiceContextInterface )
    expect(con.resource(:AnotherResource)).to be_a( ApiTools::ServiceMiddleware::ServiceEndpoint )
    expect(con.resource(:AnotherResource).interface).to be_nil
  end
end
