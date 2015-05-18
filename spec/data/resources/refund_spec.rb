require 'spec_helper'

describe Hoodoo::Data::Resources::Refund do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['basket']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['pos_reference']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['purchase_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['purchase_id'].resource).to eq(:Purchase)
  end
end
