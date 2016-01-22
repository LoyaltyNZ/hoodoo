require 'spec_helper'

describe Hoodoo::Services::Discovery::ForLocal do
  it 'stores known quantities and retrieves them' do
    r = described_class.new(
      resource: 'Foo', # Note String
      version: 3,
      base_path: '/v3/foos',
      routing_regexp: /\/v3\/foos.*/,
      de_facto_base_path: '/3/Foo',
      de_facto_routing_regexp: /\/3\/Foo.*/,
      interface_class: Array, # Just any old class
      implementation_instance: Array.new # Just any old comparable class instance
    )

    expect( r.resource                ).to eq( :Foo ) # Note Symbol
    expect( r.version                 ).to eq( 3 )
    expect( r.base_path               ).to eq( '/v3/foos' )
    expect( r.routing_regexp          ).to eq( /\/v3\/foos.*/ )
    expect( r.de_facto_base_path      ).to eq( '/3/Foo' )
    expect( r.de_facto_routing_regexp ).to eq( /\/3\/Foo.*/ )
    expect( r.interface_class         ).to eq( Array )
    expect( r.implementation_instance ).to eq( Array.new )
  end
end
