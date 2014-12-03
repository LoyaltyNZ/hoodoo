require 'spec_helper'

describe ApiTools::Data::Resources::Token do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['state']).to be_a(ApiTools::Presenters::Enum)
    expect(schema.properties['state'].required).to eq(false)
    expect(schema.properties['state'].from).to eq(['waiting', 'active', 'closed'])

    expect(schema.properties['identifier']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['identifier'].required).to eq(true)

    expect(schema.properties['member_id']).to be_a(ApiTools::Presenters::UUID)
    expect(schema.properties['member_id'].required).to eq(true)
    expect(schema.properties['member_id'].resource).to eq(:Member)
  end
end
