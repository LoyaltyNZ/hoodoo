require 'spec_helper'

describe Hoodoo::Data::Types::Permissions do
  it 'should match schema expectations' do

    # List of permitted policies
    policies = ['allow', 'deny', 'ask']

    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(2)

    # Resources hash

    expect(schema.properties['actions']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['actions'].properties.count).to eq(5)

    expect(schema.properties['actions'].properties['show']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['actions'].properties['list']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['actions'].properties['create']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['actions'].properties['update']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['actions'].properties['delete']).to be_a(Hoodoo::Presenters::Enum)


    expect(schema.properties['actions'].properties['show'].from).to match_array(policies)
    expect(schema.properties['actions'].properties['list'].from).to match_array(policies)
    expect(schema.properties['actions'].properties['create'].from).to match_array(policies)
    expect(schema.properties['actions'].properties['update'].from).to match_array(policies)
    expect(schema.properties['actions'].properties['delete'].from).to match_array(policies)

    # Else enum
    expect(schema.properties['else']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['else'].from).to match_array(policies)
  end
end
