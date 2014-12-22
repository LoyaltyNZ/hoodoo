require 'spec_helper'

describe ApiTools::ServiceMiddleware::ExceptionReporting::BaseReporter do
  class TestERBase < described_class
  end

  it 'is a singleton' do
    expect( TestERBase.instance ).to be_a( TestERBase )
  end

  it 'provides a reporting example' do
    expect {
      TestERBase.instance.report( RuntimeError.new )
    }.to raise_exception( RuntimeError )
  end
end
