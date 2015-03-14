require 'spec_helper'

describe Hoodoo::Services::Discovery::ForRemote do
  it 'stores known quantities and retrieves them' do
    r = described_class.new(
      resource: 'Foo', # Note String
      version: 3,
      wrapped_endpoint: Array.new # Just any old comparable class instance
    )

    expect( r.resource           ).to eq( :Foo ) # Note Symbol
    expect( r.version            ).to eq( 3 )
    expect( r.wrapped_endpoint   ).to eq( Array.new )
  end
end
