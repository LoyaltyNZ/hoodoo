require 'spec_helper'

describe ApiTools::Data::Resources::Purchase do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(6)

    expect(schema.properties['token_identifier']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['basket']).to be_a(ApiTools::Data::DocumentedObject)
    expect(schema.properties['pos_reference']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['estimation_id']).to be_a(ApiTools::Data::DocumentedUUID)
    expect(schema.properties['estimation_id'].resource).to eq(:Estimation)
    expect(schema.properties['calculator_id']).to be_a(ApiTools::Data::DocumentedUUID)
    expect(schema.properties['calculator_id'].resource).to eq(:Calculator)
  end
end
