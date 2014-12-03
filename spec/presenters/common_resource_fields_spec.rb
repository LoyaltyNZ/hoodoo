require "spec_helper"

describe ApiTools::Presenters::CommonResourceFields do
  it 'meets schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(4)

    expect(schema.properties['id']).to be_a(ApiTools::Presenters::UUID)
    expect(schema.properties['id'].required).to eq(true)
    expect(schema.properties['id'].resource).to be_nil
    expect(schema.properties['created_at']).to be_a(ApiTools::Presenters::DateTime)
    expect(schema.properties['created_at'].required).to eq(true)
    expect(schema.properties['kind']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['kind'].required).to eq(true)
    expect(schema.properties['language']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['language'].required).to eq(false)
  end
end
