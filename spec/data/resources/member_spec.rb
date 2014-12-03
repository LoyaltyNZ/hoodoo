require 'spec_helper'

describe ApiTools::Data::Resources::Member do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(4)

    expect(schema.properties['account_id']).to be_a(ApiTools::Presenters::UUID)
    expect(schema.properties['account_id'].resource).to eq(ApiTools::Data::Resources::Account)
    expect(schema.properties['account_id'].required).to eq(false)

    expect(schema.properties['formal_name']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['formal_name'].required).to eq(true)

    expect(schema.properties['informal_name']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['informal_name'].required).to eq(false)

    expect(schema.properties['date_of_birth']).to be_a(ApiTools::Presenters::Date)
    expect(schema.properties['date_of_birth'].required).to eq(true)
  end
end
