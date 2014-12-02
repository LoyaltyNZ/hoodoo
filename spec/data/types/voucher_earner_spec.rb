require 'spec_helper'

describe ApiTools::Data::Types::VoucherEarner do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(3)

    expect(schema.properties['product_tags_included']).to be_a(ApiTools::Presenters::Tags)
    expect(schema.properties['product_tags_excluded']).to be_a(ApiTools::Presenters::Tags)
    expect(schema.properties['voucher_earners']).to be_a(ApiTools::Presenters::Array)

    expect(schema.properties['voucher_earners'].properties['earned_via']).to be_a(ApiTools::Presenters::Object)
    expect(schema.properties['voucher_earners'].properties['build_with']).to be_a(ApiTools::Presenters::Object)

    expect(schema.properties['voucher_earners'].properties['earned_via'].properties['accumulation']).to be_a(ApiTools::Presenters::Enum)
    expect(schema.properties['voucher_earners'].properties['earned_via'].properties['accumulation'].from).to eq(['discrete', 'cumulative'])
    expect(schema.properties['voucher_earners'].properties['earned_via'].properties['source_exchange_rates']).to be_a(ApiTools::Presenters::Hash)

    expect(schema.properties['voucher_earners'].properties['earned_via'].properties['source_exchange_rates'].properties['keys']).to be_a(ApiTools::Presenters::String)
    expect(schema.properties['voucher_earners'].properties['earned_via'].properties['source_exchange_rates'].properties['keys'].length).to eq(ApiTools::Data::Types::CURRENCY_CODE_MAX_LENGTH)

    expect(schema.properties['voucher_earners'].properties['build_with'].properties['name']).to be_a(ApiTools::Presenters::Text)
  end
end
