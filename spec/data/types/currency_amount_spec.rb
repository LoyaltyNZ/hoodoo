require 'spec_helper'

describe ApiTools::Data::Types::CurrencyAmount do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties[:currency_code]).to be_a(ApiTools::Presenters::String)
    expect(schema.properties[:currency_code].length).to eq(16)
    expect(schema.properties[:qualifier]).to be_a(ApiTools::Presenters::String)
    expect(schema.properties[:qualifier].length).to eq(32)
    expect(schema.properties[:amount]).to be_a(ApiTools::Presenters::Text)
  end
end
