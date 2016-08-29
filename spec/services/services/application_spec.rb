require 'spec_helper'

class RSpecTestImplementationA < Hoodoo::Services::Implementation
end

class RSpecTestImplementationB < Hoodoo::Services::Implementation
end

class RSpecTestInterfaceA < Hoodoo::Services::Interface
  interface :RSpecTestResource do
    endpoint :rspec_test_application_a, RSpecTestImplementationA
  end
end

class RSpecTestInterfaceB < Hoodoo::Services::Interface
  interface :RSpecTestResource do
    endpoint :rspec_test_application_b, RSpecTestImplementationA
  end
end

class RSpecTestService < Hoodoo::Services::Service
end

class RSpecTestService2 < Hoodoo::Services::Service
end

describe Hoodoo::Services::Service do
  it 'should complain about incorrect interface classes' do
    expect {
      RSpecTestService.comprised_of( Hash )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Service::comprised_of expects Hoodoo::Services::Interface subclasses only - got 'Hash'")

    expect {
      RSpecTestService.comprised_of( Hoodoo::Services::Interface )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Service::comprised_of expects Hoodoo::Services::Interface subclasses only - got 'Hoodoo::Services::Interface'")
  end

  it 'should complain if called directly' do
    expect {
      RSpecTestService.new.call( nil )
    }.to raise_error(RuntimeError, "Hoodoo::Services::Service subclasses should only be called through the middleware - add 'use Hoodoo::Services::Middleware' to (e.g.) config.ru")
  end

  it 'should correctly report its component classes' do
    RSpecTestService.comprised_of( RSpecTestInterfaceA,
                                   RSpecTestInterfaceB )

    expect(RSpecTestService.component_interfaces).to eq([
      RSpecTestInterfaceA,
      RSpecTestInterfaceB
    ])

    expect(RSpecTestService.new.component_interfaces).to eq([
      RSpecTestInterfaceA,
      RSpecTestInterfaceB
    ])
  end

  it 'allows multiple calls to declare component classes and removes duplicates' do
    RSpecTestService2.comprised_of( RSpecTestInterfaceB )
    RSpecTestService2.comprised_of( RSpecTestInterfaceA )
    RSpecTestService2.comprised_of( RSpecTestInterfaceB )

    expect(RSpecTestService2.component_interfaces).to eq([
      RSpecTestInterfaceB,
      RSpecTestInterfaceA
    ])

    expect(RSpecTestService2.new.component_interfaces).to eq([
      RSpecTestInterfaceB,
      RSpecTestInterfaceA
    ])
  end
end
