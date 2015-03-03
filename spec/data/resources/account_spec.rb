require 'spec_helper'

describe Hoodoo::Data::Resources::Account do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(0)
  end
end
