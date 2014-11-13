require 'spec_helper'

describe ApiTools::Data::Types::CurrencyEarner do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['product_tags_included']).to be_a(ApiTools::Presenters::Tags)
    expect(schema.properties['product_tags_excluded']).to be_a(ApiTools::Presenters::Tags)
    expect(schema.properties['currency_earner']).to be_a(ApiTools::Data::DocumentedObject)

    expect(schema.properties['currency_earner'].properties['earned_via']).to be_a(ApiTools::Data::DocumentedHash)
    expect(schema.properties['currency_earner'].properties['default_currency_code']).to be_a(ApiTools::Data::DocumentedArray)

    expect(schema.properties['currency_earner'].properties['earned_via'].properties['keys']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['keys'].length).to eq(ApiTools::Data::Types::CURRENCY_CODE_MAX_LENGTH)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values']).to be_a(ApiTools::Data::DocumentedObject)

    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['amount']).to be_a(ApiTools::Presenters::Integer)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['qualifier']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['qualifier'].length).to eq(ApiTools::Data::Types::CURRENCY_QUALIFIER_MAX_LENGTH)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['accumulation']).to be_a(ApiTools::Presenters::Enum)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['accumulation'].from).to eq(['discrete', 'cumulative'])
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['source_exchange_rates']).to be_a(ApiTools::Data::DocumentedHash)

    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['source_exchange_rates'].properties['keys']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['source_exchange_rates'].properties['keys'].length).to eq(ApiTools::Data::Types::CURRENCY_CODE_MAX_LENGTH)
  end
end