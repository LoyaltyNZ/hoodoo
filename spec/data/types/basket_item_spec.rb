require 'spec_helper'

describe ApiTools::Data::Types::BasketItem do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(6)
    expect(schema.properties['quantity']).to be_a(ApiTools::Presenters::Integer)
    expect(schema.properties['currency_amount']).to be_a(ApiTools::Data::DocumentedObject)

    expect(schema.properties['product_id']).to be_a(ApiTools::Data::DocumentedUUID)
    expect(schema.properties['product_id'].resource).to eq(:Product)
    expect(schema.properties['product_code']).to be_a(ApiTools::Presenters::Text)

    expect(schema.properties['accrual']).to be_a(ApiTools::Presenters::Enum)
    expect(schema.properties['accrual'].from).to eq(['excluded'])

    # Nested Product type

    expect(schema.properties['product_data']).to be_a(ApiTools::Data::DocumentedObject)
    expect(schema.properties['product_data'].properties.count).to eq(4)
    expect(schema.properties['product_data'].properties['code']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['product_data'].properties['name']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['product_data'].properties['description']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['product_data'].properties['tags']).to be_a(ApiTools::Data::DocumentedTags)
  end
end
