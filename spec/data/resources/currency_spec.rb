require 'spec_helper'

describe Hoodoo::Data::Resources::Currency do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(7)

    expect(schema.properties['currency_code']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['currency_code'].length).to eq(Hoodoo::Data::Types::CURRENCY_CODE_MAX_LENGTH)
    expect(schema.properties['symbol']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['symbol'].length).to eq(Hoodoo::Data::Types::CURRENCY_SYMBOL_MAX_LENGTH)
    expect(schema.properties['qualifiers']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['precision']).to be_a(Hoodoo::Presenters::Integer)
    expect(schema.properties['grouping_level']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['grouping_level'].from).to eq(['account', 'member', 'token'])
    expect(schema.properties['position']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['position'].from).to eq(['prefix', 'suffix'])
    expect(schema.properties['rounding']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['rounding'].from.sort).to eq(['up', 'down', 'half_up', 'half_down', 'half_even'].sort)
  end

  it 'should be renderable with all data' do
    id         = Hoodoo::UUID.generate
    created_at = Time.now
    json       = described_class.render(
      {
        'currency_code' => 'X-FBP',
        'symbol' => 'pts',
        'precision' => 2,
        'qualifiers' => [ 'standard', 'bonus' ],
        'grouping_level' => 'account',
        'position' => 'suffix',
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
        'grouping_level' => 'account',
        'position' => 'suffix',
        'rounding' => 'down'
      }
    )
  end

  it 'should be renderable with minimum data' do
    id         = Hoodoo::UUID.generate
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
        'grouping_level' => 'account',
        'position' => 'suffix',
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
end
