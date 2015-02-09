require 'spec_helper'

class RSpecTestImplementationImplementation < Hoodoo::Services::Implementation
end

class RSpecTestImplementationInterface < Hoodoo::Services::Interface
  interface :RSpecTestResource do
    endpoint :rspec_test_service_stub, RSpecTestImplementationImplementation
  end
end

class RSpecTestImplementation < Hoodoo::Services::Service
  comprised_of RSpecTestImplementationInterface
end

describe Hoodoo::Services::Implementation do
  it 'should raise base class exceptions' do
    ses = Hoodoo::Services::LegacySession.new
    req = Hoodoo::Services::Request.new
    res = Hoodoo::Services::Response.new( Hoodoo::UUID.generate() )
    mid = Hoodoo::Services::Middleware.new( RSpecTestImplementation.new )
    con = Hoodoo::Services::Context.new( ses, req, res, mid )
    int = Hoodoo::Services::Implementation.new

    expect {
      int.list( con )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Implementation subclasses must implement 'list'")

    expect {
      int.show( con )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Implementation subclasses must implement 'show'")

    expect {
      int.create( con )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Implementation subclasses must implement 'create'")

    expect {
      int.update( con )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Implementation subclasses must implement 'update'")

    expect {
      int.delete( con )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Implementation subclasses must implement 'delete'")
  end
end
