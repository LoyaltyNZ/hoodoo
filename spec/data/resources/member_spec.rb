require 'spec_helper'

describe Hoodoo::Data::Resources::Member do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(1)

    expect(schema.properties['account_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['account_id'].resource).to eq(:Account)
    expect(schema.properties['account_id'].required).to eq(false)
  end
end
