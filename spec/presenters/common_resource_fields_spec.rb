require "spec_helper"

describe Hoodoo::Presenters::CommonResourceFields do
  it 'meets schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(7)

    expect(schema.properties['id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['id'].required).to eq(true)
    expect(schema.properties['id'].resource).to be_nil
    expect(schema.properties['created_at']).to be_a(Hoodoo::Presenters::DateTime)
    expect(schema.properties['created_at'].required).to eq(true)
    expect(schema.properties['kind']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['kind'].required).to eq(true)
    expect(schema.properties['language']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['language'].required).to eq(false)

    expect(schema.properties['secured_with']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['secured_with'].required).to eq(false)

    expect(schema.properties['_embed']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['_embed'].required).to eq(false)
    expect(schema.properties['_reference']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['_reference'].required).to eq(false)

  end
end
