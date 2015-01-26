require 'spec_helper'

class RSpecTestServiceImplementationImplementation < Hoodoo::ServiceImplementation
end

class RSpecTestServiceImplementationInterface < Hoodoo::ServiceInterface
  interface :RSpecTestResource do
    endpoint :rspec_test_service_stub, RSpecTestServiceImplementationImplementation
  end
end

class RSpecTestServiceImplementation < Hoodoo::ServiceApplication
  comprised_of RSpecTestServiceImplementationInterface
end

describe Hoodoo::ServiceImplementation do
  it 'should raise base class exceptions' do
    ses = Hoodoo::ServiceSession.new
    req = Hoodoo::ServiceRequest.new
    res = Hoodoo::ServiceResponse.new( Hoodoo::UUID.generate() )
    mid = Hoodoo::ServiceMiddleware.new( RSpecTestServiceImplementation.new )
    con = Hoodoo::ServiceContext.new( ses, req, res, mid )
    int = Hoodoo::ServiceImplementation.new

    expect {
      int.list( con )
    }.to raise_error(RuntimeError, "Hoodoo::ServiceImplementation subclasses must implement 'list'")

    expect {
      int.show( con )
    }.to raise_error(RuntimeError, "Hoodoo::ServiceImplementation subclasses must implement 'show'")

    expect {
      int.create( con )
    }.to raise_error(RuntimeError, "Hoodoo::ServiceImplementation subclasses must implement 'create'")

    expect {
      int.update( con )
    }.to raise_error(RuntimeError, "Hoodoo::ServiceImplementation subclasses must implement 'update'")

    expect {
      int.delete( con )
    }.to raise_error(RuntimeError, "Hoodoo::ServiceImplementation subclasses must implement 'delete'")
  end
end
