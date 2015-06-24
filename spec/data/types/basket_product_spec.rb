require 'spec_helper'

describe Hoodoo::Data::Types::BasketProduct do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(5)
    expect(schema.properties['code']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['name']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['description']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['tag_ids']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['tags']).to be_a(Hoodoo::Presenters::Tags)
  end
end
