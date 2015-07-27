require 'spec_helper'

describe Hoodoo::Data::Resources::Voucher do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(true)

    expect(schema.properties.count).to eq(10)

    expect(schema.properties['state']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['state'].from).to eq(['earned', 'burned'])
    expect(schema.properties['state'].required).to eq(true)

    expect(schema.properties['token_identifier']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['token_identifier'].required).to eq(true)

    expect(schema.properties['backdated_to']).to be_a(Hoodoo::Presenters::DateTime)
    expect(schema.properties['backdated_to'].required).to eq(false)

    expect(schema.properties['name']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['name'].required).to eq(true)

    expect(schema.properties['programme_code']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['programme_code'].required).to eq(true)

    expect(schema.properties['reference_kind']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['reference_kind'].from).to eq(['Calculation'])
    expect(schema.properties['reference_kind'].required).to eq(false)

    expect(schema.properties['reference_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['reference_id'].required).to eq(false)

    expect(schema.properties['time_to_live']).to be_a(Hoodoo::Presenters::Integer)
    expect(schema.properties['time_to_live'].required).to eq(false)

    expect(schema.properties['expires_after']).to be_a(Hoodoo::Presenters::DateTime)
    expect(schema.properties['expires_after'].required).to eq(false)

    expect(schema.properties['burn_reason']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['burn_reason'].required).to eq(false)
  end
end
