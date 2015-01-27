require 'spec_helper'

describe Hoodoo::Data::Resources::Voucher do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(4)

    expect(schema.properties['state']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['state'].from).to eq(['earned', 'burned'])
    expect(schema.properties['token_identifier']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['name']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['burn_reason']).to be_a(Hoodoo::Presenters::Hash)
  end
end
