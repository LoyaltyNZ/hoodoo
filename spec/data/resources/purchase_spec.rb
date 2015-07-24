require 'spec_helper'

describe Hoodoo::Data::Resources::Purchase do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(5)

    expect(schema.properties['token_identifier']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['backdated_to']).to be_a(Hoodoo::Presenters::DateTime)
    expect(schema.properties['basket']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['pos_reference']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['estimation_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['estimation_id'].resource).to eq(:Estimation)
  end
end
