require 'spec_helper'

describe Hoodoo::Data::Resources::PlatformifyEvent do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect( schema.properties.count ).to eq( 2 )

    expect( schema.properties[ 'token_identifier' ] ).to be_a( Hoodoo::Presenters::Text )
    expect( schema.properties[ 'token_identifier' ].required ).to eq( true )

    expect(schema.properties['sync_platformify_event_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['sync_platformify_event_id'].required).to eq(true)
    expect(schema.properties['sync_platformify_event_id'].resource).to eq(:SyncPlatformifyEvent)
  end
end