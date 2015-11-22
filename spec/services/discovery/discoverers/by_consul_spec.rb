require 'spec_helper'

describe Hoodoo::Services::Discovery::ByConsul do
  before :each do
    @d = described_class.new
  end

  # TODO: Assume static mapping and no Consul communication to mock out.

  it 'announces' do
    result = @d.announce( 'Version', '2' ) # Intentional string use
    expect( result ).to be_a( Hoodoo::Services::Discovery::ForAMQP )
    expect( result.resource ).to eq( :Version )
    expect( result.version ).to eq( 2 )
    expect( result.queue_name ).to eq( 'service.version' )
    expect( result.equivalent_path ).to eq( '/v2/versions')
  end

  it 'discovers' do
    result = @d.announce( 'Version', 2 )
    @d.instance_variable_set( '@known_local_resources', {} ) # Hack for test!

    result = @d.discover( :Version, 2 )
    expect( result.resource ).to eq( :Version )
    expect( result.version ).to eq( 2 )
    expect( result.queue_name ).to eq( 'service.version' )
    expect( result.equivalent_path ).to eq( '/v2/versions')
  end
end
