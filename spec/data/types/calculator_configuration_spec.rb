require 'spec_helper'

describe Hoodoo::Data::Types::CalculatorConfiguration do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(1)

    expect(schema.properties['calculator_data']).to be_a(Hoodoo::Presenters::Hash)

    # Copied and modified from currency_earner_spec.rb
    #
    expect(schema.properties['calculator_data'].properties['earn_currency']).to be_a(Hoodoo::Presenters::Object)

    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['product_tag_ids_included']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['product_tag_ids_excluded']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['product_tags_included']).to be_a(Hoodoo::Presenters::Tags)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['product_tags_excluded']).to be_a(Hoodoo::Presenters::Tags)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['default_currency_code']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via'].properties['keys']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via'].properties['keys'].length).to eq(Hoodoo::Data::Types::CURRENCY_CODE_MAX_LENGTH)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via'].properties['values']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via'].properties['values'].properties['amount']).to be_a(Hoodoo::Presenters::Integer)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via'].properties['values'].properties['qualifier']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via'].properties['values'].properties['qualifier'].length).to eq(Hoodoo::Data::Types::CURRENCY_QUALIFIER_MAX_LENGTH)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via'].properties['values'].properties['accumulation']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via'].properties['values'].properties['accumulation'].from).to eq(['discrete', 'cumulative'])
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via'].properties['values'].properties['source_exchange_rates']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via'].properties['values'].properties['source_exchange_rates'].properties['keys']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['currency_earner'].properties['earned_via'].properties['values'].properties['source_exchange_rates'].properties['keys'].length).to eq(Hoodoo::Data::Types::CURRENCY_CODE_MAX_LENGTH)

    # Copied and modified from voucher_earner_spec.rb
    #
    expect(schema.properties['calculator_data'].properties['earn_vouchers']).to be_a(Hoodoo::Presenters::Object)

    expect(schema.properties['calculator_data'].properties['earn_vouchers'].properties['product_tag_ids_included']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['calculator_data'].properties['earn_vouchers'].properties['product_tag_ids_excluded']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['product_tags_included']).to be_a(Hoodoo::Presenters::Tags)
    expect(schema.properties['calculator_data'].properties['earn_currency'].properties['product_tags_excluded']).to be_a(Hoodoo::Presenters::Tags)
    expect(schema.properties['calculator_data'].properties['earn_vouchers'].properties['voucher_earners']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['calculator_data'].properties['earn_vouchers'].properties['voucher_earners'].properties['earned_via']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['calculator_data'].properties['earn_vouchers'].properties['voucher_earners'].properties['build_with']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['calculator_data'].properties['earn_vouchers'].properties['voucher_earners'].properties['earned_via'].properties['accumulation']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['calculator_data'].properties['earn_vouchers'].properties['voucher_earners'].properties['earned_via'].properties['accumulation'].from).to eq(['discrete', 'cumulative'])
    expect(schema.properties['calculator_data'].properties['earn_vouchers'].properties['voucher_earners'].properties['earned_via'].properties['source_exchange_rates']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['calculator_data'].properties['earn_vouchers'].properties['voucher_earners'].properties['earned_via'].properties['source_exchange_rates'].properties['keys']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['calculator_data'].properties['earn_vouchers'].properties['voucher_earners'].properties['earned_via'].properties['source_exchange_rates'].properties['keys'].length).to eq(Hoodoo::Data::Types::CURRENCY_CODE_MAX_LENGTH)
    expect(schema.properties['calculator_data'].properties['earn_vouchers'].properties['voucher_earners'].properties['build_with'].properties['name']).to be_a(Hoodoo::Presenters::Text)
  end
end
