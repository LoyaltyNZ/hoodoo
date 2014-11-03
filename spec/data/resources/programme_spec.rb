require 'spec_helper'

describe ApiTools::Data::Resources::Programme do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(2)

    expect(schema.properties['code']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['name']).to be_a(ApiTools::Presenters::Text)
  end
end