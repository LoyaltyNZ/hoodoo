require 'spec_helper'

describe ApiTools::ServiceMiddleware::ExceptionReporting::BaseReporter do
  class TestERBase < described_class
  end

  it 'is a singleton' do
    expect( TestERBase.instance ).to be_a( TestERBase )
  end

  it 'provides a reporting example' do
    expect( ApiTools::Logger ).to receive( :debug )
    TestERBase.instance.report( RuntimeError.new )
  end
end
