require 'spec_helper'

describe ApiTools::Data::Resources::Currency do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(6)

    expect(schema.properties['currency_code']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['currency_code'].length).to eq(16)
    expect(schema.properties['symbol']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['symbol'].length).to eq(8)
    expect(schema.properties['qualifiers']).to be_a(ApiTools::Data::DocumentedArray)
    expect(schema.properties['precision']).to be_a(ApiTools::Presenters::Integer)
    expect(schema.properties['position']).to be_a(ApiTools::Presenters::Enum)
    expect(schema.properties['position'].from).to eq(['prefix', 'suffix'])
    expect(schema.properties['rounding']).to be_a(ApiTools::Presenters::Enum)
    expect(schema.properties['rounding'].from.sort).to eq(['up', 'down', 'half_up', 'half_down', 'half_even'].sort)
  end

  it 'should be renderable with all data' do
    id         = ApiTools::UUID.generate
    created_at = Time.now
    json       = described_class.render(
      {
        'currency_code' => 'X-FBP',
        'symbol' => 'pts',
        'precision' => 2,
        'qualifiers' => [ 'standard', 'bonus' ],
        'rounding' => 'down'
      },
      id,
      created_at
    )

    expect(json).to eq(
      {
        'id' => id,
        'created_at' => created_at.iso8601,
        'kind' => 'Currency',
        'currency_code' => 'X-FBP',
        'symbol' => 'pts',
        'position' => nil,
        'precision' => 2,
        'qualifiers' => [ 'standard', 'bonus' ],
        'rounding' => 'down'
      }
    )
  end

  it 'should be renderable with minimum data' do
    id         = ApiTools::UUID.generate
    created_at = Time.now
    json       = described_class.render(
      {
        'currency_code' => 'X-FBP',
        'rounding' => 'down'
      },
      id,
      created_at
    )

    expect(json).to eq(
      {
        'id' => id,
        'created_at' => created_at.iso8601,
        'kind' => 'Currency',
        'currency_code' => 'X-FBP',
        'symbol' => nil,
        'position' => nil,
        'precision' => 2,
        'qualifiers' => [],
        'rounding' => 'down'
      }
    )
  end

  it 'should be valid with all data' do
    result = described_class.validate(
      {
        'currency_code' => 'X-FBP',
        'symbol' => 'pts',
        'qualifiers' => [ 'standard', 'bonus' ],
        'rounding' => 'down'
      },
      true
    )

    expect(result).to eq([])
  end

  it 'should be valid with minimum data' do
    result = described_class.validate(
      {
        'currency_code' => 'X-FBP',
        'rounding' => 'down'
      },
      true
    )

    expect(result).to eq([])
  end

  it 'should be invalid without mandatory= data' do
    result = described_class.validate(
      {
        # Required field 'currency_code' omitted
        'symbol' => 'pts',
        'qualifiers' => [ 'standard', 'bonus' ],
        'rounding' => 'down'
      },
      true
    )

    expect(result).to eq(
      [
        {
          'code' => 'generic.required_field_missing',
          'message' => 'Field `currency_code` is required',
          'reference' => 'currency_code'
        }
      ]
    )
  end
end
