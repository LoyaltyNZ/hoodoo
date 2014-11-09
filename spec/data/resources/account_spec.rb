require 'spec_helper'

describe ApiTools::Data::Resources::Account do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(1)

    expect(schema.properties['owner_id']).to be_a(ApiTools::Presenters::UUID)
    expect(schema.properties['owner_id'].resource).to eq(ApiTools::Data::Resources::Member)
    expect(schema.properties['owner_id'].required).to eq(false)
  end
end
