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
    context 'with Airbrake mocks' do
      it 'calls Airbrake correctly without an "env"' do
        ex = RuntimeError.new( 'A' )

        expect( Airbrake ).to receive( :notify_sync ).once do | e, opts |
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

        expect( Airbrake ).to receive( :notify_sync ).once do | e, opts |
          expect( e ).to be_a( Exception )

          expect( opts ).to be_a( Hash )
          expect( opts ).to have_key( :backtrace )

          expect( opts[ :rack_env ] ).to eq( mock_env )
        end

        Hoodoo::Services::Middleware::ExceptionReporting.report( ex, mock_env )
      end
    end

    context 'without Airbrake mocks' do

      # Airbrake does not allow the default notifier to be reconfigured, so we
      # must set some dummy values here just once within this Airbrake-specific
      # integration test. Without this, non-mocked tests do not run much of the
      # Airbrake code that, over time, we have discovered should be tested.
      #
      before :all do
        Airbrake.configure do | config |
          config.project_id  = '123456'
          config.project_key = Hoodoo::UUID.generate()
        end
      end

      before :each do
        WebMock.enable!

        stub_request( :post,   /airbrake\.io\/api/ ).
           to_return( :body    => "{}",
                      :status  => 201,
                      :headers => { 'Content-Length' => 2 } )
      end

      after :each do
        WebMock.reset!
        WebMock.disable!
      end

      it 'can send frozen exceptions' do
        ex = RuntimeError.new( 'A' )

        # Be sure that the adaptero called Airbrake and that Airbrake did try
        # to internally send the message (which we'll catch with WebMock via
        # the "before :each" filter above).
        #
        expect( Airbrake ).to receive( :notify_sync ).once.and_call_original
        expect_any_instance_of( Airbrake::SyncSender ).to receive( :send ).once.and_call_original

        # There shouldn't be any need to handle exceptions inside the
        # communicator pool underneath the adaptor.
        #
        expect_any_instance_of( Hoodoo::Communicators::Pool ).to_not receive( :handle_exception )

        Hoodoo::Services::Middleware::ExceptionReporting.report( ex.freeze() )
        Hoodoo::Services::Middleware::ExceptionReporting.wait()
      end

      it 'can send frozen data large enough to require truncation' do
        ex       = RuntimeError.new( 'A' )
        mock_env = { 'rack' => 'request' }

        1.upto( Airbrake::Notice::PAYLOAD_MAX_SIZE + 10 ) do | i |
          mock_env[ Hoodoo::UUID.generate() ] = i
        end

        # See previous test (above) for an explanation of the expectations
        # below.

        expect( Airbrake ).to receive( :notify_sync ).once.and_call_original
        expect_any_instance_of( Airbrake::Truncator ).to receive( :truncate_object ).at_least( :once ).and_call_original
        expect_any_instance_of( Airbrake::SyncSender ).to receive( :send ).once.and_call_original

        expect_any_instance_of( Hoodoo::Communicators::Pool ).to_not receive( :handle_exception )

        Hoodoo::Services::Middleware::ExceptionReporting.report( ex, mock_env.freeze() )
        Hoodoo::Services::Middleware::ExceptionReporting.wait()
      end
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

      expect( Airbrake ).to receive( :notify_sync ).once do | e, opts |
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

      expect( Airbrake ).to receive( :notify_sync ).once do | e, opts |
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
