require 'spec_helper'

describe ApiTools::Data::Types::CurrencyAmount do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['currency_code']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['currency_code'].length).to eq(ApiTools::Data::Types::CURRENCY_CODE_MAX_LENGTH)
    expect(schema.properties['qualifier']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['qualifier'].length).to eq(ApiTools::Data::Types::CURRENCY_QUALIFIER_MAX_LENGTH)
    expect(schema.properties['amount']).to be_a(ApiTools::Presenters::Text)
  end
end
