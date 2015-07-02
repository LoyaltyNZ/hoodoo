require 'spec_helper'

describe Hoodoo::Data::Types::CalculatorCommon do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(4)

    expect(schema.properties['product_tag_ids_included']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['product_tag_ids_excluded']).to be_a(Hoodoo::Presenters::Array)

    expect(schema.properties['product_tags_included']).to be_a(Hoodoo::Presenters::Tags)
    expect(schema.properties['product_tags_excluded']).to be_a(Hoodoo::Presenters::Tags)
  end
end
