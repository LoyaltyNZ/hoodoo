require 'spec_helper'

describe Hoodoo::Data::Types::CurrencyEarner do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['product_tag_ids_included']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['product_tag_ids_excluded']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['currency_earner']).to be_a(Hoodoo::Presenters::Object)

    expect(schema.properties['currency_earner'].properties['earned_via']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['currency_earner'].properties['default_currency_code']).to be_a(Hoodoo::Presenters::Array)

    expect(schema.properties['currency_earner'].properties['earned_via'].properties['keys']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['keys'].length).to eq(Hoodoo::Data::Types::CURRENCY_CODE_MAX_LENGTH)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values']).to be_a(Hoodoo::Presenters::Object)

    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['amount']).to be_a(Hoodoo::Presenters::Integer)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['qualifier']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['qualifier'].length).to eq(Hoodoo::Data::Types::CURRENCY_QUALIFIER_MAX_LENGTH)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['accumulation']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['accumulation'].from).to eq(['discrete', 'cumulative'])
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['source_exchange_rates']).to be_a(Hoodoo::Presenters::Hash)

    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['source_exchange_rates'].properties['keys']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['currency_earner'].properties['earned_via'].properties['values'].properties['source_exchange_rates'].properties['keys'].length).to eq(Hoodoo::Data::Types::CURRENCY_CODE_MAX_LENGTH)
  end
end
