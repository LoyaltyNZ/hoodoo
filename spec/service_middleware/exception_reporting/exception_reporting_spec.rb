require 'spec_helper'

describe ApiTools::ServiceMiddleware::ExceptionReporting do

  class TestReporterA < ApiTools::ServiceMiddleware::ExceptionReporting::Base
    def report( e )
      expectable_hook_a( e )
      sleep 0.2 # Deliberate delay to make sure ::wait() works;
                # intermittent failures would imply it doesn't.
    end
  end

  class TestReporterB < ApiTools::ServiceMiddleware::ExceptionReporting::Base
    def report( e )
      expectable_hook_b( e )
    end
  end

  after :each do
    ApiTools::ServiceMiddleware::ExceptionReporting.wait()
  end

  it 'lets me add and remove handlers' do
    ApiTools::ServiceMiddleware::ExceptionReporting.add( TestReporterA )
    ApiTools::ServiceMiddleware::ExceptionReporting.add( TestReporterB )
    ApiTools::ServiceMiddleware::ExceptionReporting.remove( TestReporterA )
    ApiTools::ServiceMiddleware::ExceptionReporting.remove( TestReporterB )
  end

  it 'calls handler A' do
    ApiTools::ServiceMiddleware::ExceptionReporting.add( TestReporterA )
    ex = RuntimeError.new( 'A' )
    ha = { :foo => :bar }
    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex, ha )
    ApiTools::ServiceMiddleware::ExceptionReporting.report( ex, ha )
    ApiTools::ServiceMiddleware::ExceptionReporting.remove( TestReporterA )
  end

  it 'calls handler B' do
    ApiTools::ServiceMiddleware::ExceptionReporting.add( TestReporterB )
    ex = RuntimeError.new( 'B' )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex )
    ApiTools::ServiceMiddleware::ExceptionReporting.report( ex )
    ApiTools::ServiceMiddleware::ExceptionReporting.remove( TestReporterB )
  end

  it 'calls all handlers' do
    ApiTools::ServiceMiddleware::ExceptionReporting.add( TestReporterA )
    ApiTools::ServiceMiddleware::ExceptionReporting.add( TestReporterB )

    ex_one = RuntimeError.new( 'One' )
    ex_two = RuntimeError.new( 'Two' )

    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex_one )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex_one )
    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex_two )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex_two )

    ApiTools::ServiceMiddleware::ExceptionReporting.report( ex_one )
    ApiTools::ServiceMiddleware::ExceptionReporting.report( ex_two )

    ApiTools::ServiceMiddleware::ExceptionReporting.remove( TestReporterA )
    ApiTools::ServiceMiddleware::ExceptionReporting.remove( TestReporterB )
  end

  it 'complains about bad additions' do
    expect {
      ApiTools::ServiceMiddleware::ExceptionReporting.add( Object )
    }.to raise_exception( RuntimeError )
  end

  it 'complains about bad removals' do
    expect {
      ApiTools::ServiceMiddleware::ExceptionReporting.remove( Object )
    }.to raise_exception( RuntimeError )
  end
end
