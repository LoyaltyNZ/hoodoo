require 'spec_helper'

describe ApiTools::Data::Types::Basket do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(2)

    # BasketItem array

    expect(schema.properties['items']).to be_a(ApiTools::Data::DocumentedArray)

    expect(schema.properties['items'].properties.count).to eq(6)
    expect(schema.properties['items'].properties['quantity']).to be_a(ApiTools::Presenters::Integer)
    expect(schema.properties['items'].properties['currency_amounts']).to be_a(ApiTools::Data::DocumentedArray)

    expect(schema.properties['items'].properties['product_id']).to be_a(ApiTools::Data::DocumentedUUID)
    expect(schema.properties['items'].properties['product_id'].resource).to eq(:Product)
    expect(schema.properties['items'].properties['product_code']).to be_a(ApiTools::Presenters::Text)

    expect(schema.properties['items'].properties['product_data']).to be_a(ApiTools::Data::DocumentedObject)
    expect(schema.properties['items'].properties['product_data'].properties.count).to eq(4)
    expect(schema.properties['items'].properties['product_data'].properties['code']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['items'].properties['product_data'].properties['name']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['items'].properties['product_data'].properties['description']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['items'].properties['product_data'].properties['tags']).to be_a(ApiTools::Data::DocumentedTags)

    expect(schema.properties['items'].properties['accrual']).to be_a(ApiTools::Presenters::Enum)
    expect(schema.properties['items'].properties['accrual'].from).to eq(['excluded'])

    # CurrencyAmount array

    expect(schema.properties['totals']).to be_a(ApiTools::Data::DocumentedArray)

    expect(schema.properties['totals'].properties.count).to eq(3)

    expect(schema.properties['totals'].properties['currency_code']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['totals'].properties['currency_code'].length).to eq(16)
    expect(schema.properties['totals'].properties['qualifier']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['totals'].properties['qualifier'].length).to eq(32)
    expect(schema.properties['totals'].properties['amount']).to be_a(ApiTools::Presenters::Text)
  end
end
