require 'spec_helper'

describe ApiTools::Data::Resources::Balance do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(2)

    expect(schema.properties['token_identifier']).to be_a(ApiTools::Presenters::Text)
    expect(schema.properties['currency_amount']).to be_a(ApiTools::Presenters::Object)
  end
end
