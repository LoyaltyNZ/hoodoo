require 'spec_helper'

describe ApiTools::Data::Resources::Outlet do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['name']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['participant_id']).to be_a(ApiTools::Presenters::UUID)
    expect(schema.properties['participant_id'].resource).to eq(:Participant)
    expect(schema.properties['calculator_id']).to be_a(ApiTools::Presenters::UUID)
    expect(schema.properties['calculator_id'].resource).to eq(:Calculator)
  end
end
