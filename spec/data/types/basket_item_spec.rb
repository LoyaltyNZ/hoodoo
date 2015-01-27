require 'spec_helper'

describe Hoodoo::Data::Types::BasketItem do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(6)
    expect(schema.properties['quantity']).to be_a(Hoodoo::Presenters::Integer)

    # CurrencyAmount array

    expect(schema.properties['currency_amounts']).to be_a(Hoodoo::Presenters::Array)

    expect(schema.properties['currency_amounts'].properties.count).to eq(3)

    expect(schema.properties['currency_amounts'].properties['currency_code']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['currency_amounts'].properties['currency_code'].length).to eq(Hoodoo::Data::Types::CURRENCY_CODE_MAX_LENGTH)
    expect(schema.properties['currency_amounts'].properties['qualifier']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['currency_amounts'].properties['qualifier'].length).to eq(Hoodoo::Data::Types::CURRENCY_QUALIFIER_MAX_LENGTH)
    expect(schema.properties['currency_amounts'].properties['amount']).to be_a(Hoodoo::Presenters::Text)

    expect(schema.properties['product_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['product_id'].resource).to eq(:Product)
    expect(schema.properties['product_code']).to be_a(Hoodoo::Presenters::Text)

    expect(schema.properties['accrual']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['accrual'].from).to eq(['excluded'])

    # Nested Product type

    expect(schema.properties['product_data']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['product_data'].properties.count).to eq(4)
    expect(schema.properties['product_data'].properties['code']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['product_data'].properties['name']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['product_data'].properties['description']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['product_data'].properties['tags']).to be_a(Hoodoo::Presenters::Tags)
  end
end
