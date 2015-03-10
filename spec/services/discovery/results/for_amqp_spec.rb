require 'spec_helper'

describe Hoodoo::Services::Discovery::ForAMQP do
  it 'stores known quantities and retrieves them' do
    r = described_class.new(
      resource: 'Foo', # Note String
      version: 3,
      queue_name: 'queue.foo',
      equivalent_path: '/v3/foos'
    )

    expect( r.resource        ).to eq( :Foo ) # Note Symbol
    expect( r.version         ).to eq( 3 )
    expect( r.queue_name      ).to eq( 'queue.foo' )
    expect( r.equivalent_path ).to eq( '/v3/foos' )
  end
end
