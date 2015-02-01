require 'spec_helper'

describe Hoodoo::Data::Resources::Session do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['caller_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['caller_id'].resource).to eq(:Caller)
    expect(schema.properties['expired_at']).to be_a(Hoodoo::Presenters::DateTime)
    expect(schema.properties['identifier']).to be_a(Hoodoo::Presenters::Text)
  end
end
