require 'spec_helper'

describe Hoodoo::Data::Types::ResourcePermissions do
  it 'should match schema expectations' do

    # List of permitted policies
    policies = ['allow', 'deny', 'ask']

    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(2)

    # Resources hash

    expect(schema.properties['resources']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['resources'].properties.count).to eq(5)

    expect(schema.properties['resources'].properties['show']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['resources'].properties['list']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['resources'].properties['create']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['resources'].properties['update']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['resources'].properties['delete']).to be_a(Hoodoo::Presenters::Enum)


    expect(schema.properties['resources'].properties['show'].from).to match_array(policies)
    expect(schema.properties['resources'].properties['list'].from).to match_array(policies)
    expect(schema.properties['resources'].properties['create'].from).to match_array(policies)
    expect(schema.properties['resources'].properties['update'].from).to match_array(policies)
    expect(schema.properties['resources'].properties['delete'].from).to match_array(policies)

    # Else enum
    expect(schema.properties['else']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['else'].from).to match_array(policies)
  end
end
