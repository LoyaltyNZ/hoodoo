require 'spec_helper.rb'

describe ApiTools::ServiceMiddleware::ServiceRegistryDRbServer do

  # When running tests we can't assume any particular static port is free
  # on the test machine, so we must get a port dynamically. Since it might
  # take a little while for a DRb server to fully shut down "behind the
  # scenes" when we ask it to stop, its claimed port might not be free by
  # the time the 'next test' runs, so we ask for a spare port for each
  # test that runs.
  #
  before :each do
    @drb_uri = "druby://127.0.0.1:#{ ApiTools::Utilities.spare_port() }"
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
  end

  context "via DRb" do
    it 'starts as a server' do
      DRb.start_service( @drb_uri, ApiTools::ServiceMiddleware::FRONT_OBJECT )
      @drb_server = DRbObject.new_with_uri( @drb_uri )

      expect do
        @drb_server.add( :FooS, 2, 'http://localhost:3030/v2/foo_s' )
      end.to_not raise_error

      DRb.stop_service
    end

    it 'starts as a client' do
      expect {
        DRb.start_service( @drb_uri, ApiTools::ServiceMiddleware::FRONT_OBJECT )
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
      DRb.start_service( @drb_uri, ApiTools::ServiceMiddleware::FRONT_OBJECT )
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

  class RSpecTestTimeImplementation < ApiTools::ServiceImplementation
    def list( context )
      context.response.set_resources( [ { 'time' => @time_now } ] )
    end
  end

  class RSpecTestTimeInterface < ApiTools::ServiceInterface
    interface( :Time ) { endpoint :time, RSpecTestTimeImplementation }
  end

  class RSpecTestTime < ApiTools::ServiceApplication
    comprised_of RSpecTestTimeInterface
  end

  class RSpecTestClockImplementation < ApiTools::ServiceImplementation
    def list( context )
      context.response.set_resources( context.resource( :Time ).list() + [ { 'clock' => 'responded' } ] )
    end
  end

  class RSpecTestClockInterface < ApiTools::ServiceInterface
    interface( :Clock ) { endpoint :clock, RSpecTestClockImplementation }
  end

  class RSpecTestClock < ApiTools::ServiceApplication
    comprised_of RSpecTestClockInterface
  end

  context 'via middleware' do

    # Make an HTTP GET request using the given class to the given path and port.

    def run_request( path, port )
      headers    = { 'Content-Type' => 'application/json; charset=utf-8' }
      remote_uri = URI.parse( "http://127.0.0.1:#{ port }/#{ path }" )
      http       = Net::HTTP.new( remote_uri.host, remote_uri.port )
      request    = Net::HTTP::Get.new( remote_uri.request_uri() )

      request.initialize_http_header( headers )
      return http.request( request )
    end

    before :all do

      ENV[ 'APITOOLS_MIDDLEWARE_DRB_PORT_OVERRIDE' ] = ApiTools::Utilities.spare_port().to_s

      # Bring up the 'Time' resource endpoint server.

      @port1   = ApiTools::Utilities.spare_port()
      @thread1 = Thread.start do
        app1 = Rack::Builder.new do
          use ApiTools::ServiceMiddleware
          run RSpecTestClock.new
        end

        # This command never returns. The Ruby thread is not really
        # killable or manageable at all; we just let it die when the
        # whole test suite exits.

        Rack::Server.start(
          :app  => app1,
          :Host => '127.0.0.1',
          :Port => @port1,
          :server => :webrick
        )
      end

      # Wait for the server to come up. I tried many approaches. In the end,
      # only this hacky polling-talk-to-server code worked reliably.

      repeat = true
      while repeat
        begin
          run_request('', @port1)
          repeat = false
        rescue Errno::ECONNREFUSED
          sleep 0.1
        end
      end

      # Same for the 'Clock' resource endpoint server.

      @port2   = ApiTools::Utilities.spare_port()
      @thread2 = Thread.start do
        app2 = Rack::Builder.new do
          use ApiTools::ServiceMiddleware
          run RSpecTestTime.new
        end
        Rack::Server.start(
          :app  => app2,
          :Host => '127.0.0.1',
          :Port => @port2,
          :server => :webrick
        )
      end

      repeat = true
      while repeat
        begin
          run_request('', @port2)
          repeat = false
        rescue Errno::ECONNREFUSED
          sleep 0.1
        end
      end
    end

    # Above: That's a lot of support code for one little test :-) but this
    # is a significant integration test; it runs two real Webrick instances
    # each with its own service on a free HTTP port; one talks to the other
    # over local machine HTTP via the DRb service for discovery.
    #
    it 'properly supports service discovery' do
      response = run_request( '/v1/clock', @port1 )
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
