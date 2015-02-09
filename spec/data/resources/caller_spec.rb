require 'spec_helper'

describe Hoodoo::Data::Resources::Caller do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(6)

    expect(schema.properties['participant_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['participant_id'].resource).to eq(:Participant)
    expect(schema.properties['outlet_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['outlet_id'].resource).to eq(:Outlet)
    expect(schema.properties['authentication_secret']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['authorised_participant_ids']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['authorised_programme_codes']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['resources']).to be_a(Hoodoo::Presenters::Hash)
  end
end
