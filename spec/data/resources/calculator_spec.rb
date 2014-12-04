require 'spec_helper'

describe ApiTools::Data::Resources::Calculator do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(4)

    expect(schema.properties['name']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['description']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['calculator_type']).to be_a(ApiTools::Presenters::Enum)
    expect(schema.properties['calculator_type'].from).to eq(["earn_currency", "earn_vouchers"])
    expect(schema.properties['calculator_data']).to be_a(ApiTools::Presenters::Hash)
  end
end
