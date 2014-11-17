require 'spec_helper'

describe ApiTools::Data::Resources::Calculation do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    # internationalised as the voucher earner is.
    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['configuration']).to be_a(ApiTools::Presenters::Object)
    expect(schema.properties['configuration']).to be_a(ApiTools::Presenters::Object)
    expect(schema.properties['currency_amounts']).to be_a(ApiTools::Presenters::Array)
  end
end
