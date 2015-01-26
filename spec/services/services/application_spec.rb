require 'spec_helper'

class RSpecTestServiceApplicationImplementationA < Hoodoo::ServiceImplementation
end

class RSpecTestServiceApplicationImplementationB < Hoodoo::ServiceImplementation
end

class RSpecTestServiceApplicationInterfaceA < Hoodoo::ServiceInterface
  interface :RSpecTestResource do
    endpoint :rspec_test_service_application_a, RSpecTestServiceApplicationImplementationA
  end
end

class RSpecTestServiceApplicationInterfaceB < Hoodoo::ServiceInterface
  interface :RSpecTestResource do
    endpoint :rspec_test_service_application_b, RSpecTestServiceApplicationImplementationA
  end
end

class RSpecTestServiceApplication < Hoodoo::ServiceApplication
end

class RSpecTestServiceApplication2 < Hoodoo::ServiceApplication
end

describe Hoodoo::ServiceApplication do
  it 'should complain about incorrect interface classes' do
    expect {
      RSpecTestServiceApplication.comprised_of( Hash )
    }.to raise_error(RuntimeError, "Hoodoo::ServiceImplementation::comprised_of expects Hoodoo::ServiceInterface subclasses only - got 'Hash'")

    expect {
      RSpecTestServiceApplication.comprised_of( Hoodoo::ServiceInterface )
    }.to raise_error(RuntimeError, "Hoodoo::ServiceImplementation::comprised_of expects Hoodoo::ServiceInterface subclasses only - got 'Hoodoo::ServiceInterface'")
  end

  it 'should complain if called directly' do
    expect {
      RSpecTestServiceApplication.new.call( nil )
    }.to raise_error(RuntimeError, "Hoodoo::ServiceImplementation subclasses should only be called through the middleware - add 'use Hoodoo::ServiceMiddleware' to (e.g.) config.ru")
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
