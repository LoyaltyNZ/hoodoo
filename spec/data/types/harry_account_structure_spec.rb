require 'spec_helper'

describe Hoodoo::Data::Types::HarryAccountStructure do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.properties.count).to eq(5)

    expect(schema.properties['account']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['account'].required).to eq(true)

     expect(schema.properties['members']).to be_a(Hoodoo::Presenters::Array)
     expect(schema.properties['members'].required).to eq(true)

     expect(schema.properties['tokens']).to be_a(Hoodoo::Presenters::Array)
     expect(schema.properties['tokens'].required).to eq(true)

     expect(schema.properties['memberships']).to be_a(Hoodoo::Presenters::Array)
     expect(schema.properties['memberships'].required).to eq(true)

     expect(schema.properties['programmes']).to be_a(Hoodoo::Presenters::Array)
     expect(schema.properties['programmes'].required).to eq(true)
  end
end
