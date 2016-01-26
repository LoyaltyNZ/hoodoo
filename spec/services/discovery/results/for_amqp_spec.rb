require 'spec_helper'

describe Hoodoo::Services::Discovery::ForAMQP do
  it 'stores known quantities and retrieves them' do
    r = described_class.new(
      resource: 'Foo', # Note String
      version: 3
    )

    expect( r.resource     ).to eq( :Foo ) # Note Symbol
    expect( r.version      ).to eq( 3 )
    expect( r.routing_path ).to eq( '/3/Foo' )
  end
end
