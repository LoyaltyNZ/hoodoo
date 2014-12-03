require 'spec_helper'

describe ApiTools::Data::Resources::Membership do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['token_identifier']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['token_identifier'].required).to eq(true)

    expect(schema.properties['programme_id']).to be_a(ApiTools::Presenters::UUID)
    expect(schema.properties['programme_id'].required).to eq(true)
    expect(schema.properties['programme_id'].resource).to eq(ApiTools::Data::Resources::Programme)

    expect(schema.properties['calculator_data']).to be_a(ApiTools::Presenters::Hash)
    expect(schema.properties['calculator_data'].required).to eq(false)
  end
end
