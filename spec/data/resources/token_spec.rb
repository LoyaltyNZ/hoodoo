require 'spec_helper'

describe Hoodoo::Data::Resources::Token do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(6)

    expect(schema.properties['state']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['state'].required).to eq(false)
    expect(schema.properties['state'].from).to eq(['waiting', 'active', 'closed'])

    expect(schema.properties['identifier']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['identifier'].required).to eq(true)

    expect(schema.properties['member_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['member_id'].required).to eq(false)
    expect(schema.properties['member_id'].resource).to eq(:Member)

    expect(schema.properties['account_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['account_id'].required).to eq(false)
    expect(schema.properties['account_id'].resource).to eq(:Account)

    expect(schema.properties['programme_code']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['programme_code'].required).to eq(false)

    expect(schema.properties['programme_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['programme_id'].required).to eq(false)
    expect(schema.properties['programme_id'].resource).to eq(:Programme)
  end
end
