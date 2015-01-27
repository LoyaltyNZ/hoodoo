require 'spec_helper'

describe Hoodoo::Data::Types::ErrorPrimitive do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['code']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['message']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['reference']).to be_a(Hoodoo::Presenters::Text)
  end
end
