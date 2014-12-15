require 'spec_helper'

describe ApiTools::Data::Resources::Currency do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(7)

    expect(schema.properties['currency_code']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['currency_code'].length).to eq(ApiTools::Data::Types::CURRENCY_CODE_MAX_LENGTH)
    expect(schema.properties['symbol']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['symbol'].length).to eq(ApiTools::Data::Types::CURRENCY_SYMBOL_MAX_LENGTH)
    expect(schema.properties['qualifiers']).to be_a(ApiTools::Presenters::Array)
    expect(schema.properties['precision']).to be_a(ApiTools::Presenters::Integer)
    expect(schema.properties['position']).to be_a(ApiTools::Presenters::Enum)
    expect(schema.properties['position'].from).to eq(['prefix', 'suffix'])
    expect(schema.properties['rounding']).to be_a(ApiTools::Presenters::Enum)
    expect(schema.properties['rounding'].from.sort).to eq(['up', 'down', 'half_up', 'half_down', 'half_even'].sort)
    expect(schema.properties['external_currency_type']).to be_a(ApiTools::Presenters::Enum)
    expect(schema.properties['external_currency_type'].from).to match_array( [ "nz.co.loyalty.txn.fbpts", "nz.co.loyalty.txn.apd" ] )
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
        'created_at' => created_at.utc.iso8601,
        'kind' => 'Currency',
        'currency_code' => 'X-FBP',
        'symbol' => 'pts',
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
        'created_at' => created_at.utc.iso8601,
        'kind' => 'Currency',
        'currency_code' => 'X-FBP',
        'precision' => 2,
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
      false
    )

    expect(result.errors).to eq([])
  end

  it 'should be valid with minimum data' do
    result = described_class.validate(
      {
        'currency_code' => 'X-FBP',
        'rounding' => 'down'
      },
      false
    )

    expect(result.errors).to eq([])
  end

  it 'should be invalid without mandatory= data' do
    result = described_class.validate(
      {
        # Required field 'currency_code' omitted
        'symbol' => 'pts',
        'qualifiers' => [ 'standard', 'bonus' ],
        'rounding' => 'down'
      },
      false
    )

    expect(result.errors).to eq(
      [
        {
          'code' => 'generic.required_field_missing',
          'message' => 'Field `currency_code` is required',
          'reference' => 'currency_code'
        }
      ]
    )
  end

  it 'is invalid when an invalid external currency type is given' do
    result = described_class.validate(
      {
        'currency_code' => 'X-FBP',
        'rounding' => 'down',
        'external_currency_type' => 'pts'
      },
      false
    )

    expect(result.errors).to eq(
      [
        {
          'code' => 'generic.invalid_enum',
          'message' => 'Field `external_currency_type` does not contain an allowed reference value from this list: `["nz.co.loyalty.txn.fbpts", "nz.co.loyalty.txn.apd"]`',
          'reference' => 'external_currency_type'
        }
      ]
    )
  end
end
