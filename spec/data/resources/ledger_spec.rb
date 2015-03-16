require 'spec_helper'

describe Hoodoo::Data::Resources::Ledger do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)
    expect(schema.properties.count).to eq(8)

    expect(schema.properties['token_identifier']).to be_a(Hoodoo::Presenters::Text)
    expect(schema.properties['token_identifier'].required).to eq(true)

    expect(schema.properties['participant_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['participant_id'].resource).to eq(:Participant)
    expect(schema.properties['participant_id'].required).to eq(true)

    expect(schema.properties['outlet_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['outlet_id'].resource).to eq(:Outlet)
    expect(schema.properties['outlet_id'].required).to eq(true)

    expect(schema.properties['reason']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['reason'].from).to eq(['calculation', 'manipulation'])
    expect(schema.properties['reason'].required).to eq(true)

    expect(schema.properties['reference_kind']).to be_a(Hoodoo::Presenters::Enum)
    expect(schema.properties['reference_kind'].from).to eq(['Calculation', 'Credit', 'Debit'])
    expect(schema.properties['reference_kind'].required).to eq(false)

    expect(schema.properties['reference_id']).to be_a(Hoodoo::Presenters::UUID)
    expect(schema.properties['reference_id'].required).to eq(false)

    expect(schema.properties['debit']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['debit'].required).to eq(false)

    expect(schema.properties['credit']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['credit'].required).to eq(false)
  end
end
