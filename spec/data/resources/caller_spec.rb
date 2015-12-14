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

  it 'should be renderable with all data' do
    id         = Hoodoo::UUID.generate
    created_at = Time.now
    json       = described_class.render(
      {
        "name"       => "Test Caller",
        "identity"   => {
          "array"   => [],
          "integer" => 1,
          "string"  => "thisisastring",
          "object"  => { "key" => "value" }
        },
        "permissions" => {
          "resources" => {
            "Caller" => {
              "else" => "allow"
            },
            "Member" => {
              "actions" => {
                "list" => "allow"
              },
              "else"    => "deny"
            }
          }
        },
        "scoping"    => {
          "array"   => [],
          "integer" => 1,
          "string"  => "thisisastring",
          "object"  => { "key" => "value" }
        }
      },
      id,
      created_at
    )

    expect(json).to eq(
      {
        'id'         => id,
        'created_at' => created_at.utc.iso8601,
        'kind'       => 'Caller',
        "name"       => "Test Caller",
        "identity"   => {
          "array"   => [],
          "integer" => 1,
          "string"  => "thisisastring",
          "object"  => { "key" => "value" }
        },
        "permissions" => {
          "resources" => {
            "Caller" => {
              "else" => "allow"
            },
            "Member" => {
              "actions" => {
                "list" => "allow"
              },
              "else"    => "deny"
            }
          }
        },
        "scoping"    => {
          "array"   => [],
          "integer" => 1,
          "string"  => "thisisastring",
          "object"  => { "key" => "value" }
        },
        "language" => "en-nz"
      }
    )
  end

  it 'should be renderable with minimal data' do
    id         = Hoodoo::UUID.generate
    created_at = Time.now
    json       = described_class.render(
      {
        "identity"    => {},
        "permissions" => { "resources" => {} },
        "scoping"     => {}
      },
      id,
      created_at
    )

    expect(json).to eq(
      {
        'id'          => id,
        'created_at'  => created_at.utc.iso8601,
        'kind'        => 'Caller',
        "identity"    => {},
        "permissions" => { "resources" => {} },
        "scoping"     => {},
        "language"    => "en-nz"
      }
    )
  end
end
