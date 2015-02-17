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
    mid = Hoodoo::Services::Middleware.new( RSpecTestImplementation.new )
    int = Hoodoo::Services::Middleware::Interaction.new( {}, mid )
    con = int.context
    imp = Hoodoo::Services::Implementation.new

    expect {
      imp.list( con )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Implementation subclasses must implement 'list'")

    expect {
      imp.show( con )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Implementation subclasses must implement 'show'")

    expect {
      imp.create( con )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Implementation subclasses must implement 'create'")

    expect {
      imp.update( con )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Implementation subclasses must implement 'update'")

    expect {
      imp.delete( con )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Implementation subclasses must implement 'delete'")

    expect( imp.verify( con, :show ) ).to eq( Hoodoo::Services::Permissions::DENY )
  end
end
