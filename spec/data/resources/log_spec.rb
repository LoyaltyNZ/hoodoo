require 'spec_helper'

describe Hoodoo::Data::Resources::Log do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)
    expect(schema.properties.count).to eq(5)

    expect(schema.properties['level']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['level'].required).to eq(true)
    expect(schema.properties['component']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['component'].required).to eq(true)
    expect(schema.properties['code']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['code'].required).to eq(true)

    expect(schema.properties['interaction_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['data']).to be_a(Hoodoo::Presenters::Hash)
  end
end
