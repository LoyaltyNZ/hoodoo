require 'spec_helper'

describe Hoodoo::Data::Resources::Calculation do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    # internationalised as the voucher earner is.
    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(7)

    expect(schema.properties['calculator_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['token_identifier']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['reference_kind']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['reference_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['calculator_data']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['currency_amounts']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['programme_code']).to be_a(Hoodoo::Presenters::Text)
  end
end
