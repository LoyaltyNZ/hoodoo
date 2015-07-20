require 'spec_helper'

describe Hoodoo::Services::Discovery::ForHTTP do

  let( :endpoint_uri ) { URI.parse( 'http://foo.bar/v1/foos' ) }
  let( :proxy_uri    ) { URI.parse( 'http://bar.baz/v1/bars' ) }

  it 'stores mandatory quantities and retrieves them' do
    r = described_class.new(
      resource: 'Foo', # Note String
      version: 3,
      endpoint_uri: endpoint_uri(),
    )

    expect( r.resource     ).to eq( :Foo ) # Note Symbol
    expect( r.version      ).to eq( 3 )
    expect( r.endpoint_uri ).to eq( endpoint_uri() )
  end

  it 'stores all known quantities and retrieves them' do
    r = described_class.new(
      resource: :Bar, # Note Symbol
      version: 2,
      endpoint_uri: endpoint_uri(),
      proxy_uri: proxy_uri()
    )

    expect( r.resource     ).to eq( :Bar ) # Also Symbol
    expect( r.version      ).to eq( 2 )
    expect( r.endpoint_uri ).to eq( endpoint_uri() )
    expect( r.proxy_uri    ).to eq( proxy_uri() )
  end
end
