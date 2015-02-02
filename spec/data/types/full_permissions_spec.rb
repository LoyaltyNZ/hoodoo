require 'spec_helper'

describe Hoodoo::Data::Types::FullPermissions do
  it 'should match schema expectations' do

    schema = described_class.get_schema()

    expect(schema.is_internationalised?()).to eq(false)

    expect(schema.properties.count).to eq(2)

    # Resources hash
    expect(schema.properties['resources']).to be_a(Hoodoo::Presenters::Hash)
    expect(schema.properties['resources'].properties.count).to eq(2)

    # Default hash
    expect(schema.properties['default']).to be_a(Hoodoo::Presenters::Object)
    expect(schema.properties['default'].properties.count).to eq(2)

  end

  it 'should accept a valid hash' do

    errors = described_class.validate({
      'resources' => {
        'member' => {
          'actions' => {
            'list' => 'allow',
            'show' => 'ask'
          },
          'else' => 'deny'
        }
      },
      'default' => {
        'actions' => {
          'show' => 'allow'
        },
        'else' => 'deny'
      }
    })
    expect(errors.has_errors?).to be_falsey

  end
end
