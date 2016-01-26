require 'spec_helper'

describe Hoodoo::Services::Discovery::ByFlux do

  after :all do
    Hoodoo::Services::Middleware.flush_services_for_test()
  end

  context 'without a mocked service name it' do
    before :each do
      @d = described_class.new
      allow( Hoodoo::Services::Middleware ).to receive( :service_name ).and_return( 'service.Version' )
    end

    it 'announces' do
      result = @d.announce( 'Version', '2' ) # Intentional string use

      expect( result ).to be_a( Hoodoo::Services::Discovery::ForAMQP )
      expect( result.resource ).to eq( :Version )
      expect( result.version ).to eq( 2 )
      expect( result.routing_path ).to eq( '/2/Version')
    end

    it 'discovers local' do
               @d.announce( :Version,   2  )
      result = @d.discover( 'Version', '2' )

      expect( result ).to be_a( Hoodoo::Services::Discovery::ForAMQP )
      expect( result.resource ).to eq( :Version )
      expect( result.version ).to eq( 2 )
      expect( result.routing_path ).to eq( '/2/Version')
    end

    it 'discovers remote' do
      result = @d.discover( 'External', 1 )

      expect( result ).to be_a( Hoodoo::Services::Discovery::ForAMQP )
      expect( result.resource ).to eq( :External )
      expect( result.version ).to eq( 1 )
      expect( result.routing_path ).to eq( '/1/External')
    end
  end

  context 'with a real service list it' do

    class FluxDiscovererImplementationA < Hoodoo::Services::Implementation; end
    class FluxDiscovererImplementationB < Hoodoo::Services::Implementation; end
    class FluxDiscovererImplementationC < Hoodoo::Services::Implementation; end

    class FluxDiscovererInterfaceA < Hoodoo::Services::Interface
      interface :InterfaceA do
        endpoint :a_interfaces, FluxDiscovererImplementationA
        version 1
      end
    end

    class FluxDiscovererInterfaceB < Hoodoo::Services::Interface
      interface :InterfaceB do
        endpoint :b_interfaces, FluxDiscovererImplementationA
        version 2
      end
    end

    class FluxDiscovererInterfaceC < Hoodoo::Services::Interface
      interface :InterfaceC do
        endpoint :c_interfaces, FluxDiscovererImplementationA
        version 3
      end
    end

    # Intentionally not in alphabetical order, to check for reordering in
    # service name / queue name environment variable later.
    #
    class FluxDiscovererService < Hoodoo::Services::Service
      comprised_of FluxDiscovererInterfaceB,
                   FluxDiscovererInterfaceA,
                   FluxDiscovererInterfaceC
    end

    before :each do
      Hoodoo::Services::Middleware.flush_services_for_test()
      @d = described_class.new
    end

    it 'announces and sets environment variables' do
      ENV.delete( 'ALCHEMY_SERVICE_NAME'   )
      ENV.delete( 'ALCHEMY_RESOURCE_PATHS' )

      expect_any_instance_of( Hoodoo::Services::Middleware ).to receive( :announce_presence_of ) do | instance, services |
        result = @d.announce( :InterfaceA, '1', { :services => services } )

        expect( result ).to be_a( Hoodoo::Services::Discovery::ForAMQP )
        expect( result.resource ).to eq( :InterfaceA )
        expect( result.version ).to eq( 1 )
        expect( result.routing_path ).to eq( '/1/InterfaceA')
      end

      Hoodoo::Services::Middleware.new( FluxDiscovererService.new )

      expect( ENV[ 'ALCHEMY_SERVICE_NAME'   ] ).to eq( 'service.InterfaceA_InterfaceB_InterfaceC' )
      expect( ENV[ 'ALCHEMY_RESOURCE_PATHS' ].split( ',' ) ).to match_array(
        %w{ /v1/a_interfaces /1/InterfaceA /v2/b_interfaces /2/InterfaceB /v3/c_interfaces /3/InterfaceC }
      )
    end

    it 'discovers local' do
      expect_any_instance_of( Hoodoo::Services::Middleware ).to receive( :announce_presence_of ) do | instance, services |
                 @d.announce( :InterfaceC,   3, { :services => services } )
        result = @d.discover( 'InterfaceC', '3' )

        expect( result ).to be_a( Hoodoo::Services::Discovery::ForAMQP )
        expect( result.resource ).to eq( :InterfaceC )
        expect( result.version ).to eq( 3 )
        expect( result.routing_path ).to eq( '/3/InterfaceC')
      end

      Hoodoo::Services::Middleware.new( FluxDiscovererService.new )
    end

    it 'discovers remote' do
      expect_any_instance_of( Hoodoo::Services::Middleware ).to receive( :announce_presence_of ) do | instance, services |
        result = @d.discover( 'External', 1 )

        expect( result ).to be_a( Hoodoo::Services::Discovery::ForAMQP )
        expect( result.resource ).to eq( :External )
        expect( result.version ).to eq( 1 )
        expect( result.routing_path ).to eq( '/1/External')
      end

      Hoodoo::Services::Middleware.new( FluxDiscovererService.new )
    end

  end
end
