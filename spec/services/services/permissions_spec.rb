require 'spec_helper'

describe Hoodoo::Services::Permissions do
  it 'initialises with a "deny" default fallback' do
    p = described_class.new

    expect( p.to_h ).to eq({
      'default' => { 'else' => described_class::DENY }
    })
  end

  it 'sets default fallback' do
    p = described_class.new

    p.set_default_fallback( described_class::ALLOW )

    expect( p.to_h ).to eq({
      'default' => { 'else' => described_class::ALLOW }
    })
  end

  it 'sets default actions' do
    p = described_class.new

    p.set_default( 'create', described_class::ALLOW )
    p.set_default( 'update', described_class::ASK   )
    p.set_default( 'delete', described_class::DENY  )

    expect( p.to_h ).to eq({
      'default' => {
        'actions' => {
          'create' => described_class::ALLOW,
          'update' => described_class::ASK,
          'delete' => described_class::DENY
        },
        'else' => described_class::DENY
      }
    })
  end

  it 'sets resource fallback' do
    p = described_class.new

    p.set_resource_fallback( :Foo, described_class::ALLOW )
    p.set_resource_fallback( :Bar, described_class::ASK )

    expect( p.to_h ).to eq({
      'default' => {
        'else' => described_class::DENY
      },
      'resources' => {
        'Foo' => {
          'else' => described_class::ALLOW
        },
        'Bar' => {
          'else' => described_class::ASK
        }
      }
    })
  end

  it 'set resource actions' do
    p = described_class.new

    p.set_resource( :Foo, 'create', described_class::ALLOW )
    p.set_resource( :Foo, 'update', described_class::ASK   )

    p.set_resource_fallback( :Foo, described_class::ALLOW )

    p.set_resource( :Bar, 'show',   described_class::DENY  )
    p.set_resource( :Bar, 'delete', described_class::ALLOW )

    expect( p.to_h ).to eq({
      'default' => {
        'else' => described_class::DENY
      },
      'resources' => {
        'Foo' => {
          'actions' => {
            'create' => described_class::ALLOW,
            'update' => described_class::ASK
          },
          'else' => described_class::ALLOW
        },
        'Bar' => {
          'actions' => {
            'show' => described_class::DENY,
            'delete' => described_class::ALLOW
          }
        }
      }
    })
  end

  it 'loads from a Hash' do
    p1 = described_class.new
    p2 = described_class.new

    p2.set_default_fallback( described_class::ALLOW )

    p2.set_default( 'create', described_class::ALLOW )
    p2.set_default( 'update', described_class::ASK   )
    p2.set_default( 'delete', described_class::DENY  )

    p1.from_h( p2.to_h )

    expect( p1.to_h ).to eq({
      'default' => {
        'actions' => {
          'create' => described_class::ALLOW,
          'update' => described_class::ASK,
          'delete' => described_class::DENY
        },
        'else' => described_class::ALLOW
      }
    })
  end
end
