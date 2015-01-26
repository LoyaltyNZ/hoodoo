require 'spec_helper'

describe Hoodoo::ServiceMiddleware::ExceptionReporting do

  class TestReporterA < Hoodoo::ServiceMiddleware::ExceptionReporting::BaseReporter
    def report( e, env = nil )
      expectable_hook_a( e, env )
      sleep 0.2 # Deliberate delay to make sure ::wait() works;
                # intermittent failures would imply it doesn't.
    end
  end

  class TestReporterB < Hoodoo::ServiceMiddleware::ExceptionReporting::BaseReporter
    def report( e, env = nil )
      expectable_hook_b( e, env )
    end
  end

  class TestReporterC < Hoodoo::ServiceMiddleware::ExceptionReporting::BaseReporter
    def report( e, env = nil )
      raise 'I am broken'
    end
  end

  after :each do
    Hoodoo::ServiceMiddleware::ExceptionReporting.wait()
    Hoodoo::ServiceMiddleware::ExceptionReporting.remove( TestReporterA )
    Hoodoo::ServiceMiddleware::ExceptionReporting.remove( TestReporterB )
    Hoodoo::ServiceMiddleware::ExceptionReporting.remove( TestReporterC )
  end

  it 'lets me add and remove handlers' do
    Hoodoo::ServiceMiddleware::ExceptionReporting.add( TestReporterA )
    Hoodoo::ServiceMiddleware::ExceptionReporting.add( TestReporterB )
    Hoodoo::ServiceMiddleware::ExceptionReporting.remove( TestReporterA )
    Hoodoo::ServiceMiddleware::ExceptionReporting.remove( TestReporterB )
  end

  it 'calls handler A' do
    Hoodoo::ServiceMiddleware::ExceptionReporting.add( TestReporterA )
    ex = RuntimeError.new( 'A' )
    ha = { :foo => :bar }
    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex, ha )
    Hoodoo::ServiceMiddleware::ExceptionReporting.report( ex, ha )
  end

  it 'calls handler B' do
    Hoodoo::ServiceMiddleware::ExceptionReporting.add( TestReporterB )
    ex = RuntimeError.new( 'B' )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex, nil )
    Hoodoo::ServiceMiddleware::ExceptionReporting.report( ex )
  end

  it 'calls all handlers' do
    Hoodoo::ServiceMiddleware::ExceptionReporting.add( TestReporterA )
    Hoodoo::ServiceMiddleware::ExceptionReporting.add( TestReporterB )

    ex_one = RuntimeError.new( 'One' )
    ex_two = RuntimeError.new( 'Two' )

    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex_one, nil )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex_one, nil )
    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex_two, nil )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex_two, nil )

    Hoodoo::ServiceMiddleware::ExceptionReporting.report( ex_one, nil )
    Hoodoo::ServiceMiddleware::ExceptionReporting.report( ex_two, nil )
  end

  it 'complains about bad additions' do
    expect {
      Hoodoo::ServiceMiddleware::ExceptionReporting.add( Object )
    }.to raise_exception( RuntimeError )
  end

  it 'complains about bad removals' do
    expect {
      Hoodoo::ServiceMiddleware::ExceptionReporting.remove( Object )
    }.to raise_exception( RuntimeError )
  end

  it 'ignores exceptions in reporters' do
    Hoodoo::ServiceMiddleware::ExceptionReporting.add( TestReporterC ) # Add "exception raiser first
    Hoodoo::ServiceMiddleware::ExceptionReporting.add( TestReporterA ) # Then this after, which should still be called

    ex = RuntimeError.new( 'A' )
    ha = { :foo => :bar }

    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex, ha )
    Hoodoo::ServiceMiddleware::ExceptionReporting.report( ex, ha )
  end
end
