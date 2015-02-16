require 'spec_helper.rb'

describe Hoodoo::Services::Middleware::ServiceRegistryDRbServer do

  # When running tests we can't assume any particular static port is free
  # on the test machine, so we must get a port dynamically. Since it might
  # take a little while for a DRb server to fully shut down "behind the
  # scenes" when we ask it to stop, its claimed port might not be free by
  # the time the 'next test' runs, so we ask for a spare port for each
  # test that runs.
  #
  before :each do
    @drb_uri = "druby://127.0.0.1:#{ Hoodoo::Utilities.spare_port() }"
  end

  context "class instance" do
    before do
      @inst = described_class.new
    end

    it 'adds and reads endpoints' do
      @inst.add( :Foo, 2, 'http://localhost:3030/v2/foo' )
      @inst.add( :Foo, 1, 'http://127.0.0.1:3031/v1/foo' )
      @inst.add( :Bar, 1, 'http://0.0.0.0:3032/v1/bar' )

      expect( @inst.find( :Foo, 1 ) ).to eq( 'http://127.0.0.1:3031/v1/foo' )
      expect( @inst.find( :Bar, 1 ) ).to eq( 'http://0.0.0.0:3032/v1/bar' )
      expect( @inst.find( :Foo, 2 ) ).to eq( 'http://localhost:3030/v2/foo' )
      expect( @inst.find( :Bar, 2 ) ).to be_nil
    end

    # RCov report coverage only; tests elsewhere call these but code runs
    # in unusual execution contexts and doesn't get reported as covered.
    #
    it '#ping' do
      expect( @inst.ping() ).to eq( true )
    end
    #
    # (See #ping above).
    #
    it '#stop' do

      # Ensure DRb.thread.exit() is called by the 'stop' method, without
      # needing to have that code actually execute (since this requires an
      # active DRb thread and RCov doesn't report the code as covered).

      drb_thread = double()
      expect( DRb ).to receive( :thread ).once.and_return( drb_thread )
      expect( drb_thread ).to receive( :exit ).once
      @inst.stop()
    end
  end

  context "via DRb" do
    it 'starts as a server' do
      DRb.start_service( @drb_uri, Hoodoo::Services::Middleware::FRONT_OBJECT )
      @drb_server = DRbObject.new_with_uri( @drb_uri )

      expect do
        @drb_server.add( :FooS, 2, 'http://localhost:3030/v2/foo_s' )
      end.to_not raise_error

      DRb.stop_service
    end

    it 'runs in a thread, can be pinged and shuts down' do
      expect {
        port = Hoodoo::Utilities.spare_port().to_s

        thread = Thread.new do
          ENV[ 'HOODOO_MIDDLEWARE_DRB_PORT_OVERRIDE' ] = port
          described_class.start()
          ENV.delete( 'HOODOO_MIDDLEWARE_DRB_PORT_OVERRIDE' )
        end

        client = nil

        begin
          Timeout::timeout( 5 ) do
            loop do
              begin
                client = DRbObject.new_with_uri( described_class.uri() )
                client.ping()
                client.stop()
                break
              rescue DRb::DRbConnError
                sleep 0.1
              end
            end
          end
        rescue Timeout::Error
          raise "Timed out while waiting for DRb service registry to start"
        end

        # For good measure...
        #
        ENV.delete( 'HOODOO_MIDDLEWARE_DRB_PORT_OVERRIDE' )

      }.to_not raise_error
    end

    it 'starts as a client' do
      expect {
        DRb.start_service( @drb_uri, Hoodoo::Services::Middleware::FRONT_OBJECT )
        @drb_server = DRbObject.new_with_uri( @drb_uri )
        @drb_server.add( :FooS2, 2, 'http://localhost:3030/v2/foo_s2' )

        Thread.new do
          DRb.start_service
          @drb_client = DRbObject.new_with_uri( @drb_uri )
          @drb_client.add( :FooC, 2, 'http://localhost:3030/v2/foo_c' )
        end.join

        DRb.stop_service

      }.to_not raise_error
    end

    it 'synchronises data' do
      DRb.start_service( @drb_uri, Hoodoo::Services::Middleware::FRONT_OBJECT )
      @drb_server = DRbObject.new_with_uri( @drb_uri )

      @drb_server.add( :Foo1, 2, 'http://localhost:3030/v2/foo_1' )
      @drb_server.add( :Foo1, 1, 'http://127.0.0.1:3031/v1/foo_1' )

      one = Thread.new do
        DRb.start_service
        @drb_client = DRbObject.new_with_uri( @drb_uri )
        @drb_client.add( :Bar1, 1, 'http://0.0.0.0:3032/v1/bar_1' )

        expect( @drb_client.find( :Foo1, 1 ) ).to eq( 'http://127.0.0.1:3031/v1/foo_1' )
        expect( @drb_client.find( :Foo1, 2 ) ).to eq( 'http://localhost:3030/v2/foo_1' )
        expect( @drb_client.find( :Foo1, 3 ) ).to be_nil

        @drb_client.add( :Bar1, 1, 'http://0.0.0.0:3032/v1/bar_1' )
      end.join

      expect( @drb_server.find( :Bar1, 1 ) ).to eq( 'http://0.0.0.0:3032/v1/bar_1' )

      DRb.stop_service
    end
  end

  # A lot of this is copied from service_middleware_multi_spec.rb and
  # it'd be cleaner if all these tests were in that one file, but it
  # is nice to keep the tests specifically aimed at DRb here (even if
  # a whole bunch of other stuff gets caught in the integration test).

  @time_now = Time.now.to_s

  class RSpecTestTimeImplementation < Hoodoo::Services::Implementation
    def list( context )
      context.response.set_resources( [ { 'time' => @time_now } ] )
    end
  end

  class RSpecTestTimeInterface < Hoodoo::Services::Interface
    interface( :RSpecDRbTestTime ) { endpoint :rspec_drb_test_time, RSpecTestTimeImplementation }
  end

  class RSpecTestTime < Hoodoo::Services::Service
    comprised_of RSpecTestTimeInterface
  end

  class RSpecTestClockImplementation < Hoodoo::Services::Implementation
    def list( context )
      context.response.set_resources( context.resource( :RSpecDRbTestTime ).list() + [ { 'clock' => 'responded' } ] )
    end
  end

  class RSpecTestClockInterface < Hoodoo::Services::Interface
    interface( :RSpecDRbTestClock ) { endpoint :rspec_drb_test_clock, RSpecTestClockImplementation }
  end

  class RSpecTestClock < Hoodoo::Services::Service
    comprised_of RSpecTestClockInterface
  end

  context 'via middleware' do

    before :all do
      @port1 = spec_helper_start_svc_app_in_thread_for( RSpecTestClock )
      @port2 = spec_helper_start_svc_app_in_thread_for( RSpecTestTime  )
    end

    # This is a significant integration test; two real Webrick instances
    # each with its own service on a free HTTP port; one talks to the other
    # over local machine HTTP via the DRb service for discovery.
    #
    it 'properly supports service discovery' do
      response = spec_helper_http( path: '/v1/rspec_drb_test_clock', port: @port1 )
      expect( response.code ).to eq( '200' )

      parsed = JSON.parse( response.body )
      expect( parsed ).to eq( {
        '_data' => [
          { 'time'  => @time_now   },
          { 'clock' => 'responded' }
        ]
      } )
    end
  end
end
