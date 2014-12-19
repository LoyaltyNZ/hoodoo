require 'spec_helper'

describe ApiTools::Data::Types::Currency do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(6)

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
  end
end
