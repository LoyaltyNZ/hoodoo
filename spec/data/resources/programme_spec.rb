require 'spec_helper'

describe Hoodoo::Data::Resources::Programme do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(4)

    expect(schema.properties['code']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['name']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['calculator_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['calculator_id'].resource).to eq(:Calculator)
    expect(schema.properties['calculator_data']).to be_a(Hoodoo::Presenters::Hash)
  end
end
