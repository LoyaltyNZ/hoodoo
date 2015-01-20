require 'spec_helper'

class RSpecTestServiceImplementationImplementation < ApiTools::ServiceImplementation
end

class RSpecTestServiceImplementationInterface < ApiTools::ServiceInterface
  interface :RSpecTestResource do
    endpoint :rspec_test_service_stub, RSpecTestServiceImplementationImplementation
  end
end

class RSpecTestServiceImplementation < ApiTools::ServiceApplication
  comprised_of RSpecTestServiceImplementationInterface
end

describe ApiTools::ServiceImplementation do
  it 'should raise base class exceptions' do
    ses = ApiTools::ServiceSession.new
    req = ApiTools::ServiceRequest.new
    res = ApiTools::ServiceResponse.new
    mid = ApiTools::ServiceMiddleware.new( RSpecTestServiceImplementation.new )
    con = ApiTools::ServiceContext.new( ses, req, res, mid )
    int = ApiTools::ServiceImplementation.new

    expect {
      int.list( con )
    }.to raise_error(RuntimeError, "ApiTools::ServiceImplementation subclasses must implement 'list'")

    expect {
      int.show( con )
    }.to raise_error(RuntimeError, "ApiTools::ServiceImplementation subclasses must implement 'show'")

    expect {
      int.create( con )
    }.to raise_error(RuntimeError, "ApiTools::ServiceImplementation subclasses must implement 'create'")

    expect {
      int.update( con )
    }.to raise_error(RuntimeError, "ApiTools::ServiceImplementation subclasses must implement 'update'")

    expect {
      int.delete( con )
    }.to raise_error(RuntimeError, "ApiTools::ServiceImplementation subclasses must implement 'delete'")
  end
end
