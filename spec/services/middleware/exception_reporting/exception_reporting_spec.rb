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

  class TestReporterD < Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter
    def report( e, env = nil )
      expectable_hook_d1( e, env )
    end

    def contextual_report( e, context )
      expectable_hook_d2( e, context )
    end
  end

  after :each do
    Hoodoo::Services::Middleware::ExceptionReporting.wait()
    Hoodoo::Services::Middleware::ExceptionReporting.remove( TestReporterA )
    Hoodoo::Services::Middleware::ExceptionReporting.remove( TestReporterB )
    Hoodoo::Services::Middleware::ExceptionReporting.remove( TestReporterC )
    Hoodoo::Services::Middleware::ExceptionReporting.remove( TestReporterD )
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

  context 'with contextual reporting' do
    before :each do
      Hoodoo::Services::Middleware::ExceptionReporting.add( TestReporterD )
    end

    it 'supports normal behaviour' do
      ex = RuntimeError.new( 'D' )
      ha = { :foo => :bar }

      expect( TestReporterD.instance ).to receive( :expectable_hook_d1 ).once.with( ex, ha )
      Hoodoo::Services::Middleware::ExceptionReporting.report( ex, ha )
    end

    it 'supports contextual behaviour' do
      ex = RuntimeError.new( 'D' )
      co = { :bar => :baz }

      expect( TestReporterD.instance ).to receive( :expectable_hook_d2 ).once.with( ex, co )
      Hoodoo::Services::Middleware::ExceptionReporting.contextual_report( ex, co )
    end

    context 'falling back to normal' do
      before :each do
        Hoodoo::Services::Middleware::ExceptionReporting.add( TestReporterA )
      end

      # When falling back, it should extract the Rack env (mocked here) from
      # the context and pass that to the normal reporter.
      #
      it 'extracts the Rack "env"' do
        ex = RuntimeError.new( 'D' )
        ha = { :foo => :bar }
        co = OpenStruct.new

        co.owning_interaction = OpenStruct.new
        co.owning_interaction.rack_request = OpenStruct.new
        co.owning_interaction.rack_request.env = ha

        expect( TestReporterD.instance ).to receive( :expectable_hook_d2 ).once.with( ex, co )
        expect( TestReporterA.instance ).to receive( :expectable_hook_a  ).once.with( ex, ha )

        Hoodoo::Services::Middleware::ExceptionReporting.contextual_report( ex, co )
      end

      # If it can't extract the Rack request from the context when falling back,
      # the normal reporter should just be called with a "nil" second parameter.
      #
      it 'recovers from bad contexts' do
        ex = RuntimeError.new( 'D' )
        co = { :bar => :baz }

        expect( TestReporterD.instance ).to receive( :expectable_hook_d2 ).once.with( ex, co  )
        expect( TestReporterA.instance ).to receive( :expectable_hook_a  ).once.with( ex, nil )

        Hoodoo::Services::Middleware::ExceptionReporting.contextual_report( ex, co )
      end
    end
  end
end
