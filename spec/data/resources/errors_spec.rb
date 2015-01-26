require 'spec_helper'

describe Hoodoo::Data::Resources::Errors do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(2)

    expect(schema.properties['interaction_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['interaction_id'].required).to eq(false)

    expect(schema.properties['errors']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['errors'].required).to eq(true)

    expect(schema.properties['errors'].properties.count).to eq(3)
    expect(schema.properties['errors'].properties['code']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['errors'].properties['message']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['errors'].properties['reference']).to be_a(Hoodoo::Presenters::Text)
  end
end
