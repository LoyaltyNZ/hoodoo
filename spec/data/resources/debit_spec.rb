require 'spec_helper'

describe Hoodoo::Data::Resources::Debit do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect( schema.is_internationalised?() ).to eq( true )
    expect( schema.properties.count ).to eq( 4 )

    expect( schema.properties[ 'token_identifier' ] ).to be_a( Hoodoo::Presenters::Text )
    expect( schema.properties[ 'token_identifier' ].required ).to eq( true )

    expect( schema.properties[ 'client_id' ] ).to be_a( Hoodoo::Presenters::Text )
    expect( schema.properties[ 'client_id' ].required ).to eq( true )

    expect( schema.properties[ 'description' ] ).to be_a( Hoodoo::Presenters::Text )
    expect( schema.properties[ 'description' ].required ).to eq( false )

    expect( schema.properties[ 'currency_amount' ] ).to be_a( Hoodoo::Presenters::Object )
    expect( schema.properties[ 'currency_amount' ].required ).to eq( true )
  end
end
