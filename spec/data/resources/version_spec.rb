require 'spec_helper'

describe ApiTools::Data::Resources::Version do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(3)
    expect(schema.properties['major']).to be_a(ApiTools::Presenters::Integer)
    expect(schema.properties['minor']).to be_a(ApiTools::Presenters::Integer)
    expect(schema.properties['patch']).to be_a(ApiTools::Presenters::Integer)
  end
end
