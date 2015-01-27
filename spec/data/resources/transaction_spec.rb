require 'spec_helper'

describe Hoodoo::Data::Resources::Transaction do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(9)

    expect(schema.properties['client_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['business_operation']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['description']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['transaction_time']).to be_a(Hoodoo::Presenters::DateTime)
    expect(schema.properties['client_processed_time']).to be_a(Hoodoo::Presenters::DateTime)
    expect(schema.properties['platform_processed_time']).to be_a(Hoodoo::Presenters::DateTime)
    expect(schema.properties['destination_token_identifier']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['source_token_identifier']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['currency_amounts']).to be_a(Hoodoo::Presenters::Array)
  end
end
