require 'spec_helper'

describe Hoodoo::Data::Resources::SyncPlatformifyEvent do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect( schema.properties.count ).to eq( 2 )

    expect(schema.properties['harry_account_structure']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['harry_account_structure'].required).to eq(true)

    expect(schema.properties['platform_sync_ids']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['platform_sync_ids'].required).to eq(true)

    expect(schema.properties['platform_sync_ids'].properties.count).to eq(5)
    expect(schema.properties['platform_sync_ids'].properties['account']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['platform_sync_ids'].properties['members']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['platform_sync_ids'].properties['tokens']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['platform_sync_ids'].properties['memberships']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['platform_sync_ids'].properties['programmes']).to be_a(Hoodoo::Presenters::Array)

  end
end