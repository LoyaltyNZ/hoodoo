require 'spec_helper'

describe Hoodoo::Data::Types::PermissionsDefaults do
  it 'should match schema expectations' do

    # List of permitted policies
    policies = ['allow', 'deny', 'ask']

    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(1)

    # Resources hash

    expect(schema.properties['default']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['default'].properties.count).to eq(2)

    expect(schema.properties['default'].properties['actions']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['default'].properties['else']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['default'].properties['else'].from).to match_array(policies)
  end
end
