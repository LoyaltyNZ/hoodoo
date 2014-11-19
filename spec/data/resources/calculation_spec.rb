require 'spec_helper'

describe ApiTools::Data::Resources::Calculation do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    # internationalised as the voucher earner is.
    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(4)

    expect(schema.properties['calculator_id']).to be_a(ApiTools::Presenters::UUID)
    expect(schema.properties['token_identifier']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['calculator_data']).to be_a(ApiTools::Data::DocumentedHash)
    expect(schema.properties['currency_amounts']).to be_a(ApiTools::Presenters::Array)
  end
end