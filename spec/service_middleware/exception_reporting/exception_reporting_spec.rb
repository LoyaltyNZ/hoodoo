require 'spec_helper'

describe ApiTools::ServiceMiddleware::ExceptionReporting do

  class TestReporterA < ApiTools::ServiceMiddleware::ExceptionReporting::Base
    def report( e, env = nil )
      expectable_hook_a( e, env )
      sleep 0.2 # Deliberate delay to make sure ::wait() works;
                # intermittent failures would imply it doesn't.
    end
  end

  class TestReporterB < ApiTools::ServiceMiddleware::ExceptionReporting::Base
    def report( e, env = nil )
      expectable_hook_b( e, env )
    end
  end

  class TestReporterC < ApiTools::ServiceMiddleware::ExceptionReporting::Base
    def report( e, env = nil )
      raise 'I am broken'
    end
  end

  after :each do
    ApiTools::ServiceMiddleware::ExceptionReporting.wait()
    ApiTools::ServiceMiddleware::ExceptionReporting.remove( TestReporterA )
    ApiTools::ServiceMiddleware::ExceptionReporting.remove( TestReporterB )
    ApiTools::ServiceMiddleware::ExceptionReporting.remove( TestReporterC )
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
  end

  it 'calls handler B' do
    ApiTools::ServiceMiddleware::ExceptionReporting.add( TestReporterB )
    ex = RuntimeError.new( 'B' )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex, nil )
    ApiTools::ServiceMiddleware::ExceptionReporting.report( ex )
  end

  it 'calls all handlers' do
    ApiTools::ServiceMiddleware::ExceptionReporting.add( TestReporterA )
    ApiTools::ServiceMiddleware::ExceptionReporting.add( TestReporterB )

    ex_one = RuntimeError.new( 'One' )
    ex_two = RuntimeError.new( 'Two' )

    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex_one, nil )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex_one, nil )
    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex_two, nil )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex_two, nil )

    ApiTools::ServiceMiddleware::ExceptionReporting.report( ex_one, nil )
    ApiTools::ServiceMiddleware::ExceptionReporting.report( ex_two, nil )
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

  it 'ignores exceptions in reporters' do
    ApiTools::ServiceMiddleware::ExceptionReporting.add( TestReporterC ) # Add "exception raiser first
    ApiTools::ServiceMiddleware::ExceptionReporting.add( TestReporterA ) # Then this after, which should still be called

    ex = RuntimeError.new( 'A' )
    ha = { :foo => :bar }

    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex, ha )
    ApiTools::ServiceMiddleware::ExceptionReporting.report( ex, ha )
  end
end
