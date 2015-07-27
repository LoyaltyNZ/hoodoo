require 'spec_helper'

describe Hoodoo::Data::Resources::Credit do
  it 'should match schema expectations' do
    schema = described_class.get_schema()

    expect( schema.is_internationalised?() ).to eq( true )
    expect( schema.properties.count ).to eq( 5 )

    expect( schema.properties[ 'token_identifier' ] ).to be_a( Hoodoo::Presenters::Text )
    expect( schema.properties[ 'token_identifier' ].required ).to eq( true )

    expect( schema.properties[ 'backdated_to' ] ).to be_a( Hoodoo::Presenters::DateTime )
    expect( schema.properties[ 'backdated_to' ].required ).to eq( false )

    expect( schema.properties[ 'caller_reference' ] ).to be_a( Hoodoo::Presenters::Text )
    expect( schema.properties[ 'caller_reference' ].required ).to eq( true )

    expect( schema.properties[ 'description' ] ).to be_a( Hoodoo::Presenters::Text )
    expect( schema.properties[ 'description' ].required ).to eq( false )

    expect( schema.properties[ 'currency_amount' ] ).to be_a( Hoodoo::Presenters::Object )
    expect( schema.properties[ 'currency_amount' ].required ).to eq( true )
  end
end
