require 'spec_helper'

describe ApiTools::Data::Resources::Involvement do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['outlet_id']).to be_a(ApiTools::Presenters::UUID)
    expect(schema.properties['outlet_id'].resource).to eq(:Outlet)
    expect(schema.properties['programme_id']).to be_a(ApiTools::Presenters::UUID)
    expect(schema.properties['programme_id'].resource).to eq(:Programme)
    expect(schema.properties['calculator_data']).to be_a(ApiTools::Presenters::Object)
  end
end
