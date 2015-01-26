require 'spec_helper'

describe Hoodoo::Services::Middleware::ExceptionReporting do

  class TestReporterA < Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter
    def report( e, env = nil )
      expectable_hook_a( e, env )
      sleep 0.2 # Deliberate delay to make sure ::wait() works;
                # intermittent failures would imply it doesn't.
    end
  end

  class TestReporterB < Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter
    def report( e, env = nil )
      expectable_hook_b( e, env )
    end
  end

  class TestReporterC < Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter
    def report( e, env = nil )
      raise 'I am broken'
    end
  end

  after :each do
    Hoodoo::Services::Middleware::ExceptionReporting.wait()
    Hoodoo::Services::Middleware::ExceptionReporting.remove( TestReporterA )
    Hoodoo::Services::Middleware::ExceptionReporting.remove( TestReporterB )
    Hoodoo::Services::Middleware::ExceptionReporting.remove( TestReporterC )
  end

  it 'lets me add and remove handlers' do
    Hoodoo::Services::Middleware::ExceptionReporting.add( TestReporterA )
    Hoodoo::Services::Middleware::ExceptionReporting.add( TestReporterB )
    Hoodoo::Services::Middleware::ExceptionReporting.remove( TestReporterA )
    Hoodoo::Services::Middleware::ExceptionReporting.remove( TestReporterB )
  end

  it 'calls handler A' do
    Hoodoo::Services::Middleware::ExceptionReporting.add( TestReporterA )
    ex = RuntimeError.new( 'A' )
    ha = { :foo => :bar }
    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex, ha )
    Hoodoo::Services::Middleware::ExceptionReporting.report( ex, ha )
  end

  it 'calls handler B' do
    Hoodoo::Services::Middleware::ExceptionReporting.add( TestReporterB )
    ex = RuntimeError.new( 'B' )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex, nil )
    Hoodoo::Services::Middleware::ExceptionReporting.report( ex )
  end

  it 'calls all handlers' do
    Hoodoo::Services::Middleware::ExceptionReporting.add( TestReporterA )
    Hoodoo::Services::Middleware::ExceptionReporting.add( TestReporterB )

    ex_one = RuntimeError.new( 'One' )
    ex_two = RuntimeError.new( 'Two' )

    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex_one, nil )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex_one, nil )
    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex_two, nil )
    expect( TestReporterB.instance ).to receive( :expectable_hook_b ).once.with( ex_two, nil )

    Hoodoo::Services::Middleware::ExceptionReporting.report( ex_one, nil )
    Hoodoo::Services::Middleware::ExceptionReporting.report( ex_two, nil )
  end

  it 'complains about bad additions' do
    expect {
      Hoodoo::Services::Middleware::ExceptionReporting.add( Object )
    }.to raise_exception( RuntimeError )
  end

  it 'complains about bad removals' do
    expect {
      Hoodoo::Services::Middleware::ExceptionReporting.remove( Object )
    }.to raise_exception( RuntimeError )
  end

  it 'ignores exceptions in reporters' do
    Hoodoo::Services::Middleware::ExceptionReporting.add( TestReporterC ) # Add "exception raiser first
    Hoodoo::Services::Middleware::ExceptionReporting.add( TestReporterA ) # Then this after, which should still be called

    ex = RuntimeError.new( 'A' )
    ha = { :foo => :bar }

    expect( TestReporterA.instance ).to receive( :expectable_hook_a ).once.with( ex, ha )
    Hoodoo::Services::Middleware::ExceptionReporting.report( ex, ha )
  end
end
