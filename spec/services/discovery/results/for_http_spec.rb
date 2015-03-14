require 'spec_helper'

describe Hoodoo::Services::Discovery::ForHTTP do
  it 'stores known quantities and retrieves them' do
    r = described_class.new(
      resource: 'Foo', # Note String
      version: 3,
      endpoint_uri: URI.parse( 'http://foo.bar/v1/foos' )
    )

    expect( r.resource     ).to eq( :Foo ) # Note Symbol
    expect( r.version      ).to eq( 3 )
    expect( r.endpoint_uri ).to eq( URI.parse( 'http://foo.bar/v1/foos' ) )
  end
end
