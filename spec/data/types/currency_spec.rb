require 'spec_helper'

describe ApiTools::Data::Types::Currency do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(4)

    expect(schema.properties[:currency_code]).to be_a(ApiTools::Presenters::String)
    expect(schema.properties[:currency_code].length).to eq(16)
    expect(schema.properties[:symbol]).to be_a(ApiTools::Presenters::String)
    expect(schema.properties[:symbol].length).to eq(8)
    expect(schema.properties[:multiplier]).to be_a(ApiTools::Presenters::Integer)
    expect(schema.properties[:qualifiers]).to be_a(ApiTools::Data::DocumentedArray)
  end
end
