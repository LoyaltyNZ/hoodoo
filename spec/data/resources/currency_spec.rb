require 'spec_helper'

describe ApiTools::Data::Resources::Currency do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(4)

    expect(schema.properties[:currency_code]).to be_a(ApiTools::Presenters::String)
    expect(schema.properties[:currency_code].length).to eq(16)
    expect(schema.properties[:symbol]).to be_a(ApiTools::Presenters::String)
    expect(schema.properties[:symbol].length).to eq(8)
    expect(schema.properties[:multiplier]).to be_a(ApiTools::Presenters::Integer)
    expect(schema.properties[:qualifiers]).to be_a(ApiTools::Data::DocumentedArray)
  end

  it 'should be renderable with all data' do
    id         = ApiTools::UUID.generate
    created_at = Time.now
    json       = described_class.render(
      {
        currency_code: 'X-FBP',
        symbol:        'pts',
        multiplier:    100,
        qualifiers:    [ 'standard', 'bonus' ]
      },
      id,
      created_at
    )

    expect(json).to eq(
      {
        id: id,
        created_at: created_at.iso8601,
        kind: 'Currency',
        currency_code: 'X-FBP',
        symbol: 'pts',
        multiplier: 100,
        qualifiers: [ 'standard', 'bonus' ]
      }
    )
  end

  it 'should be renderable with minimum data' do
    id         = ApiTools::UUID.generate
    created_at = Time.now
    json       = described_class.render(
      {
        currency_code: 'X-FBP',
      },
      id,
      created_at
    )

    expect(json).to eq(
      {
        id: id,
        created_at: created_at.iso8601,
        kind: 'Currency',
        currency_code: 'X-FBP',
        symbol: nil,
        multiplier: nil,
        qualifiers: []
      }
    )
  end

  it 'should be valid with all data' do
    result = described_class.validate(
      {
        currency_code: 'X-FBP',
        symbol:        'pts',
        multiplier:    100,
        qualifiers:    [ 'standard', 'bonus' ]
      },
      true
    )

    expect(result).to eq([])
  end

  it 'should be valid with minimum data' do
    result = described_class.validate(
      {
        currency_code: 'X-FBP'
      },
      true
    )

    expect(result).to eq([])
  end

  it 'should be invalid without mandatory= data' do
    result = described_class.validate(
      {
        # Required field 'currency_code' omitted
        symbol:     'pts',
        multiplier: 100,
        qualifiers: [ 'standard', 'bonus' ]
      },
      true
    )

    expect(result).to eq(
      [
        {
          :code => 'generic.required_field_missing',
          :message => 'Field `currency_code` is required',
          :reference => 'currency_code'
        }
      ]
    )
  end
end
