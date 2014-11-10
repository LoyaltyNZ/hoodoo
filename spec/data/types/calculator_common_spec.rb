require 'spec_helper'

describe ApiTools::Data::Types::CalculatorCommon do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(2)

    expect(schema.properties['product_tags_included']).to be_a(ApiTools::Presenters::Tags)
    expect(schema.properties['product_tags_excluded']).to be_a(ApiTools::Presenters::Tags)
  end
end
