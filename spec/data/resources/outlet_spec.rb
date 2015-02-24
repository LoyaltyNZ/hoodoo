require 'spec_helper'

describe Hoodoo::Data::Resources::Outlet do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(2)

    expect(schema.properties['name']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['participant_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['participant_id'].resource).to eq(:Participant)
  end
end
