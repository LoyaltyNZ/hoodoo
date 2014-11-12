require 'spec_helper'

class RSpecTestServiceApplicationImplementationA < ApiTools::ServiceImplementation
end

class RSpecTestServiceApplicationImplementationB < ApiTools::ServiceImplementation
end

class RSpecTestServiceApplicationInterfaceA < ApiTools::ServiceInterface
  interface :RSpecTestResource do
    endpoint :rspec_test_service_application_a, RSpecTestServiceApplicationImplementationA
  end
end

class RSpecTestServiceApplicationInterfaceB < ApiTools::ServiceInterface
  interface :RSpecTestResource do
    endpoint :rspec_test_service_application_b, RSpecTestServiceApplicationImplementationA
  end
end

class RSpecTestServiceApplication < ApiTools::ServiceApplication
end

class RSpecTestServiceApplication2 < ApiTools::ServiceApplication
end

describe ApiTools::ServiceApplication do
  it 'should complain about incorrect interface classes' do
    expect {
      RSpecTestServiceApplication.comprised_of( Hash )
    }.to raise_error(RuntimeError, "ApiTools::ServiceImplementation::comprised_of expects ApiTools::ServiceInterface subclasses only - got 'Hash'")

    expect {
      RSpecTestServiceApplication.comprised_of( ApiTools::ServiceInterface )
    }.to raise_error(RuntimeError, "ApiTools::ServiceImplementation::comprised_of expects ApiTools::ServiceInterface subclasses only - got 'ApiTools::ServiceInterface'")
  end

  it 'should complain if called directly' do
    expect {
      RSpecTestServiceApplication.new.call( nil )
    }.to raise_error(RuntimeError, "ApiTools::ServiceImplementation subclasses should only be called through the middleware - add 'use ApiTools::ServiceMiddleware' to (e.g.) config.ru")
  end

  it 'should correctly report its component classes' do
    RSpecTestServiceApplication.comprised_of( RSpecTestServiceApplicationInterfaceA,
                                              RSpecTestServiceApplicationInterfaceB )

    expect(RSpecTestServiceApplication.component_interfaces).to eq([
      RSpecTestServiceApplicationInterfaceA,
      RSpecTestServiceApplicationInterfaceB
    ])

    expect(RSpecTestServiceApplication.new.component_interfaces).to eq([
      RSpecTestServiceApplicationInterfaceA,
      RSpecTestServiceApplicationInterfaceB
    ])
  end

  it 'allows multiple calls to declare component classes and removes duplicates' do
    RSpecTestServiceApplication2.comprised_of( RSpecTestServiceApplicationInterfaceB )
    RSpecTestServiceApplication2.comprised_of( RSpecTestServiceApplicationInterfaceA )
    RSpecTestServiceApplication2.comprised_of( RSpecTestServiceApplicationInterfaceB )

    expect(RSpecTestServiceApplication2.component_interfaces).to eq([
      RSpecTestServiceApplicationInterfaceB,
      RSpecTestServiceApplicationInterfaceA
    ])

    expect(RSpecTestServiceApplication2.new.component_interfaces).to eq([
      RSpecTestServiceApplicationInterfaceB,
      RSpecTestServiceApplicationInterfaceA
    ])
  end
end
