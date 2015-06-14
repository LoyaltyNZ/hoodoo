require 'spec_helper'

describe Hoodoo::Data::Resources::MassTagEvent do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(4)

    expect(schema.properties['resource_kind']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['resource_identifiers']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['tagging_action']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['tag_ids']).to be_a(Hoodoo::Presenters::Array)
  end
end
