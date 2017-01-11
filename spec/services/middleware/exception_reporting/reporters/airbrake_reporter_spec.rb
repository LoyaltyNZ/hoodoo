require 'spec_helper'
require 'airbrake'

# This doesn't test the Airbrake gem / configuration itself - just check that
# the appropriate Airbrake method gets called.

describe Hoodoo::Services::Middleware::ExceptionReporting::AirbrakeReporter do

  before :each do
    Hoodoo::Services::Middleware::ExceptionReporting.add( described_class )
  end

  after :each do
    Hoodoo::Services::Middleware::ExceptionReporting.wait()
    Hoodoo::Services::Middleware::ExceptionReporting.remove( described_class )
  end

  context '#report' do
    it 'calls Airbrake correctly without an "env"' do
      ex = RuntimeError.new( 'A' )

      expect( Airbrake ).to receive( :notify ).once do | e, opts |
        expect( e ).to be_a( Exception )
        expect( opts ).to be_a( Hash )
        expect( opts ).to have_key( :backtrace )
        expect( opts ).to_not have_key( :rack_env )
      end

      Hoodoo::Services::Middleware::ExceptionReporting.report( ex )
    end

    it 'calls Airbrake correctly with an "env"' do
      ex       = RuntimeError.new( 'A' )
      mock_env = { 'rack' => 'request' }

      expect( Airbrake ).to receive( :notify ).once do | e, opts |
        expect( e ).to be_a( Exception )

        expect( opts ).to be_a( Hash )
        expect( opts ).to have_key( :backtrace )

        expect( opts[ :rack_env ] ).to eq( mock_env )
      end

      Hoodoo::Services::Middleware::ExceptionReporting.report( ex, mock_env )
    end
  end

  context '#contextual_report' do
    it 'calls Airbrake correctly' do
      ex             = RuntimeError.new( 'A' )
      co             = OpenStruct.new
      mock_user_data = { :foo => :bar }
      mock_env       = { 'rack' => 'request' }

      co.owning_interaction                  = OpenStruct.new
      co.owning_interaction.rack_request     = OpenStruct.new
      co.owning_interaction.rack_request.env = mock_env

      expect( described_class.instance ).to receive( :user_data_for ).once.and_return( mock_user_data )

      expect( Airbrake ).to receive( :notify ).once do | e, opts |
        expect( e ).to be_a( Exception )

        expect( opts ).to be_a( Hash )
        expect( opts ).to have_key( :backtrace )

        expect( opts[ :rack_env         ] ).to eq( mock_env )
        expect( opts[ :environment_name ] ).to eq( 'test' )
        expect( opts[ :session          ] ).to eq( mock_user_data )
      end

      Hoodoo::Services::Middleware::ExceptionReporting.contextual_report( ex, co )
    end

    it 'has special case handling for user data recovery failure' do
      ex       = RuntimeError.new( 'A' )
      co       = OpenStruct.new
      mock_env = { 'rack' => 'request' }

      co.owning_interaction                  = OpenStruct.new
      co.owning_interaction.rack_request     = OpenStruct.new
      co.owning_interaction.rack_request.env = mock_env

      expect( described_class.instance ).to receive( :user_data_for ).once.and_return( nil )

      expect( Airbrake ).to receive( :notify ).once do | e, opts |
        expect( e ).to be_a( Exception )

        expect( opts ).to be_a( Hash )
        expect( opts ).to have_key( :backtrace )

        expect( opts[ :rack_env         ] ).to eq( mock_env )
        expect( opts[ :environment_name ] ).to eq( 'test' )
        expect( opts[ :session          ] ).to eq( 'unknown' )
      end

      Hoodoo::Services::Middleware::ExceptionReporting.contextual_report( ex, co )
    end
  end
end
