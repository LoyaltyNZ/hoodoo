require 'spec_helper'

describe Hoodoo::Data::Types::VoucherEarner do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(5)

    expect(schema.properties['product_tag_ids_included']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['product_tag_ids_excluded']).to be_a(Hoodoo::Presenters::Array)
    expect(schema.properties['product_tags_included']).to be_a(Hoodoo::Presenters::Tags)
    expect(schema.properties['product_tags_excluded']).to be_a(Hoodoo::Presenters::Tags)
    expect(schema.properties['voucher_earners']).to be_a(Hoodoo::Presenters::Array)

    expect(schema.properties['voucher_earners'].properties['earned_via']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['voucher_earners'].properties['build_with']).to be_a(Hoodoo::Presenters::Object)

    expect(schema.properties['voucher_earners'].properties['earned_via'].properties['accumulation']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['voucher_earners'].properties['earned_via'].properties['accumulation'].from).to eq(['discrete', 'cumulative'])
    expect(schema.properties['voucher_earners'].properties['earned_via'].properties['source_exchange_rates']).to be_a(Hoodoo::Presenters::Hash)

    expect(schema.properties['voucher_earners'].properties['earned_via'].properties['source_exchange_rates'].properties['keys']).to be_a(Hoodoo::Presenters::String)
    expect(schema.properties['voucher_earners'].properties['earned_via'].properties['source_exchange_rates'].properties['keys'].length).to eq(Hoodoo::Data::Types::CURRENCY_CODE_MAX_LENGTH)

    expect(schema.properties['voucher_earners'].properties['build_with'].properties['name']).to be_a(Hoodoo::Presenters::Text)
  end
end
