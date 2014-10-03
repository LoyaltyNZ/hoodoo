require 'spec_helper'

describe ApiTools::Data::Resources::Errors do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(1)
    expect(schema.properties[:errors]).to be_a(ApiTools::Data::DocumentedArray)

    expect(schema.properties[:errors].properties.count).to eq(3)
    expect(schema.properties[:errors].properties[:code]).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties[:errors].properties[:message]).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties[:errors].properties[:reference]).to be_a(ApiTools::Presenters::Text)
  end
end
