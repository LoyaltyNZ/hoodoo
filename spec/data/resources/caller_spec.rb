require 'spec_helper'

describe Hoodoo::Data::Resources::Caller do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(5)

    expect(schema.properties['authentication_secret']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['name']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['identity']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['permissions']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['permissions'].properties['resources']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['identity']).to be_a(Hoodoo::Presenters::Hash)
  end

  it 'should allow arbitrary identity values' do
    result = described_class.validate(
      {
        "identity" => {
          "array"   => [],
          "integer" => 1,
          "string"  => "thisisastring",
          "object"  => { "key" => "value" }
        },
        "permissions" => {
          "resources" => {}
        },
        "scoping" => {}
      },
      false
    )

    expect(result.errors).to eq([])
  end

  it 'should allow arbitrary scoping values' do
    result = described_class.validate(
      {
        "identity" => {},
        "permissions" => {
          "resources" => {}
        },
        "scoping" => {
          "array"   => [],
          "integer" => 1,
          "string"  => "thisisastring",
          "object"  => { "key" => "value" }
        }
      },
      false
    )

    expect(result.errors).to eq([])
  end
end
