require 'spec_helper'
require 'raygun4ruby'

# This doesn't test the Raygun gem / configuration itself - just check that
# the appropriate Raygun method gets called.

describe Hoodoo::Services::Middleware::ExceptionReporting::RaygunReporter do

  before :each do
    Hoodoo::Services::Middleware::ExceptionReporting.add( described_class )
  end

  after :each do
    Hoodoo::Services::Middleware::ExceptionReporting.wait()
    Hoodoo::Services::Middleware::ExceptionReporting.remove( described_class )
  end

  context '#report' do
    it 'calls Raygun correctly without an "env"' do
      ex = RuntimeError.new( 'A' )

      expect( Raygun ).to receive( :track_exception ).once do | e, opts |
        expect( e ).to be_a( Exception )
        expect( opts ).to be_nil
      end

      Hoodoo::Services::Middleware::ExceptionReporting.report( ex )
    end

    it 'calls Raygun correctly with an "env"' do
      ex       = RuntimeError.new( 'A' )
      mock_env = { 'rack' => 'request' }

      expect( Raygun ).to receive( :track_exception ).once do | e, opts |
        expect( e ).to be_a( Exception )

        expect( opts ).to be_a( Hash )
        expect( opts ).to eq( mock_env )
      end

      Hoodoo::Services::Middleware::ExceptionReporting.report( ex, mock_env )
    end
  end

  context '#contextual_report' do
    it 'calls Raygun correctly' do
      ex             = RuntimeError.new( 'A' )
      co             = OpenStruct.new
      mock_user_data = { :foo => :bar }
      mock_env       = { 'rack' => 'request' }

      co.owning_interaction                  = OpenStruct.new
      co.owning_interaction.rack_request     = OpenStruct.new
      co.owning_interaction.rack_request.env = mock_env

      expect( described_class.instance ).to receive( :user_data_for ).once.and_return( mock_user_data )

      expect( Raygun ).to receive( :track_exception ).once do | e, opts |
        expect( e ).to be_a( Exception )

        expect( opts ).to be_a( Hash )
        expect( opts ).to eq( mock_env.merge( :custom_data => mock_user_data ) )
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

      expect( Raygun ).to receive( :track_exception ).once do | e, opts |
        expect( e ).to be_a( Exception )

        expect( opts ).to be_a( Hash )
        expect( opts ).to eq( mock_env.merge( :custom_data => { 'user_data' => 'unknown' } ) )
      end

      Hoodoo::Services::Middleware::ExceptionReporting.contextual_report( ex, co )
    end
  end
end
