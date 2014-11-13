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
end
