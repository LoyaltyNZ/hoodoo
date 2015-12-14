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

  context 'with a resource but no resource fallback' do
    before :each do
      @p = described_class.new

      @p.set_default_fallback( described_class::ASK )

      @p.set_resource( :Foo, 'create', described_class::ALLOW )
      @p.set_resource( :Foo, 'update', described_class::ASK   )
      @p.set_resource( :Foo, 'delete', described_class::DENY  )

      @expected = {
        'resources' => {
          'Foo' => {
            'actions' => {
              'create' => described_class::ALLOW,
              'update' => described_class::ASK,
              'delete' => described_class::DENY
            }
          },
        },
        'default' => {
          'else' => described_class::ASK
        }
      }
    end

    it 'can be used to initialise a new instance as a Hash' do
      p = described_class.new( @p.to_h )
      expect( p.to_h ).to eq( @expected )
    end

    it 'behaves correctly' do
      expect( @p.permitted?( :Foo, :create ) ).to eq( described_class::ALLOW )
      expect( @p.permitted?( :Foo, :show ) ).to eq( described_class::ASK )
      expect( @p.permitted?( :Foo, :list ) ).to eq( described_class::ASK )
      expect( @p.permitted?( :Foo, :update ) ).to eq( described_class::ASK )
      expect( @p.permitted?( :Foo, :delete ) ).to eq( described_class::DENY )
    end
  end

  context 'with permissions set' do
    before :each do
      @p = described_class.new

      @p.set_default_fallback( described_class::DENY )

      @p.set_default( 'create', described_class::ASK   )
      @p.set_default( 'update', described_class::DENY  )
      @p.set_default( 'delete', described_class::ALLOW )

      @p.set_resource( :Foo, 'create', described_class::ALLOW )
      @p.set_resource( :Foo, 'update', described_class::ASK   )
      @p.set_resource( :Foo, 'delete', described_class::DENY  )

      @p.set_resource_fallback( :Foo, described_class::ALLOW )

      @expected = {
        'resources' => {
          'Foo' => {
            'actions' => {
              'create' => described_class::ALLOW,
              'update' => described_class::ASK,
              'delete' => described_class::DENY
            },
            'else' => described_class::ALLOW
          },
        },
        'default' => {
          'actions' => {
            'create' => described_class::ASK,
            'update' => described_class::DENY,
            'delete' => described_class::ALLOW
          },
          'else' => described_class::DENY
        }
      }
    end

    it 'can be loaded into another instance as a Hash' do
      p = described_class.new
      p.from_h!( @p.to_h )
      expect( p.to_h ).to eq( @expected )
    end

    it 'can be used to initialise a new instance as a Hash' do
      p = described_class.new( @p.to_h )
      expect( p.to_h ).to eq( @expected )
    end

    it 'merges' do
      p = described_class.new
      p.set_resource_fallback( :Foo, described_class::ASK )
      p.set_default( 'show', described_class::ALLOW )
      p.set_default( 'update', described_class::ALLOW )
      p.set_resource( :Bar, 'show', described_class::ALLOW )
      @p.merge!( p.to_h )
      expect( @p.to_h ).to eq( {
        'resources' => {
          'Foo' => {
            'actions' => {
              'create' => described_class::ALLOW,
              'update' => described_class::ASK,
              'delete' => described_class::DENY
            },
            'else' => described_class::ASK
          },
          'Bar' => {
            'actions' => {
              'show' => described_class::ALLOW
            }
          }
        },
        'default' => {
          'actions' => {
            'show'   => described_class::ALLOW,
            'create' => described_class::ASK,
            'update' => described_class::ALLOW,
            'delete' => described_class::ALLOW
          },
          'else' => described_class::DENY
        }
      } )
    end

    it 'allows correctly' do
      expect( @p.permitted?( :Foo, :create ) ).to eq( described_class::ALLOW )
      expect( @p.permitted?( :Foo, :show ) ).to eq( described_class::ALLOW )
      expect( @p.permitted?( :Foo, :list ) ).to eq( described_class::ALLOW )
    end

    it 'asks correctly' do
      expect( @p.permitted?( :Foo, :update ) ).to eq( described_class::ASK )
    end

    it 'denies correctly' do
      expect( @p.permitted?( :Foo, :delete ) ).to eq( described_class::DENY )
    end

    it 'action defaults work' do
      expect( @p.permitted?( :Bar, :create ) ).to eq( described_class::ASK )
      expect( @p.permitted?( :Bar, :update ) ).to eq( described_class::DENY )
      expect( @p.permitted?( :Bar, :delete ) ).to eq( described_class::ALLOW )
    end

    it 'fallback default works' do
      expect( @p.permitted?( :Bar, :show ) ).to eq( described_class::DENY )
      expect( @p.permitted?( :Bar, :list ) ).to eq( described_class::DENY )
    end

    it 'empty hashes deny' do
      @p.from_h!( {} )
      expect( @p.permitted?( :Bar, :show ) ).to eq( described_class::DENY )
    end
  end
end
