require 'spec_helper'

describe Hoodoo::Utilities do

  describe '#symbolize' do
    it 'should symbolize keys on a nested hash' do
      data = {
        'one' => 1,
        'two' => {
          'three' => :three,
          'four' => {
            :five => 'five',
            'six' => '6'
          }
        }
      }

      data[0] = 'zero'

      expect(Hoodoo::Utilities.symbolize(data)).to eq({
        :'0' => 'zero',
        :one => 1,
        :two => {
          :three => :three,
          :four => {
            :five => 'five',
            :six => '6'
          }
        }
      })
    end

    it 'should handle outer arrays' do
      data = [
        {
          'one' => 1,
          'two' => {
            'three' => :three,
            'four' => {
              :five => 'five',
              'six' => '6'
            }
          }
        },
        {
          'one' => 5,
          'two' => {
            'three' => :three,
            'four' => {
              :five => 'five',
              'six' => '6'
            }
          }
        }
      ]

      expect(Hoodoo::Utilities.symbolize(data)).to eq([
        {
          :one => 1,
          :two => {
            :three => :three,
            :four => {
              :five => 'five',
              :six => '6'
            }
          }
        },
        {
          :one => 5,
          :two => {
            :three => :three,
            :four => {
              :five => 'five',
              :six => '6'
            }
          }
        }
      ])
    end

    it 'should handle inner arrays' do

      data = {
        'one' => 1,
        'two' => [
          {
            'three' => :three,
            'four' => {
              :five => 'five',
              'six' => '6'
            }
          },
          {
            'three' => :nine,
            'four' => {
              :five => 'five',
              'six' => '6'
            }
          },
        ]
      }

      expect(Hoodoo::Utilities.symbolize(data)).to eq({
        :one => 1,
        :two => [
          {
            :three => :three,
            :four => {
              :five => 'five',
              :six => '6'
            }
          },
          {
            :three => :nine,
            :four => {
              :five => 'five',
              :six => '6'
            }
          }
        ]
      })
    end
  end

  describe '#stringify' do
    it 'should stringify keys on a nested hash' do
      data = {
        :one => 1,
        :two => {
          :three => :three,
          :four => {
            'five' => 'five',
            :six => '6'
          }
        }
      }

      data[0] = 'zero'

      expect(Hoodoo::Utilities.stringify(data)).to eq({
        '0' => 'zero',
        'one' => 1,
        'two' => {
          'three' => :three,
          'four' => {
            'five' => 'five',
            'six' => '6'
          }
        }
      })
    end

    it 'should handle outer arrays' do
      data = [
        {
          :one => 1,
          :two => {
            :three => :three,
            :four => {
              'five' => 'five',
              :six => '6'
            }
          }
        },
        {
          :one => 5,
          :two => {
            :three => :three,
            :four => {
              'five' => 'five',
              :six => '6'
            }
          }
        }
      ]

      expect(Hoodoo::Utilities.stringify(data)).to eq([
        {
          'one' => 1,
          'two' => {
            'three' => :three,
            'four' => {
              'five' => 'five',
              'six' => '6'
            }
          }
        },
        {
          'one' => 5,
          'two' => {
            'three' => :three,
            'four' => {
              'five' => 'five',
              'six' => '6'
            }
          }
        }
      ])
    end

    it 'should handle inner arrays' do

      data = {
        'one' => 1,
        'two' => [
          {
            :three => :three,
            :four => {
              :five => 'five',
              'six' => '6'
            }
          },
          {
            :three => :nine,
            :four => {
              :five => 'five',
              'six' => '6'
            }
          },
        ]
      }

      expect(Hoodoo::Utilities.stringify(data)).to eq({
        'one' => 1,
        'two' => [
          {
            'three' => :three,
            'four' => {
              'five' => 'five',
              'six' => '6'
            }
          },
          {
            'three' => :nine,
            'four' => {
              'five' => 'five',
              'six' => '6'
            }
          }
        ]
      })
    end
  end

  describe '#deep_dup' do
    it 'survives non-duplicable duplication attempts' do
      fixnum = 2
      expect( Hoodoo::Utilities.deep_dup( fixnum ).object_id ).to eq( fixnum.object_id )
    end

    it 'duplicates simple things' do
      str = 'hello world'
      expect( Hoodoo::Utilities.deep_dup( str ) ).to eq( str )
      expect( Hoodoo::Utilities.deep_dup( str ).object_id ).to_not eq( str.object_id )
    end

    it 'duplicates arrays' do
      h = { :foo => :bar }
      a = [ 1, 2, h ]

      # Make sure Ruby works :-P - changing 'h' should change the array's
      # apparent contents, since the array entry is by-reference to 'h'.

      expect( a ).to eq( [ 1, 2, { :foo => :bar } ] )
      h[ :foo ] = :baz
      expect( a ).to eq( [ 1, 2, { :foo => :baz } ] )

      expect( Hoodoo::Utilities.deep_dup( a ) ).to eq( a )
      expect( Hoodoo::Utilities.deep_dup( a ).object_id ).to_not eq( a.object_id )
      expect( Hoodoo::Utilities.deep_dup( a )[ 2 ].object_id ).to_not eq( h.object_id )

      # Changing 'h' should not change the duplicated array's apparent
      # contents, because the array values were duplicated if #deep_dup is
      # working.

      dup = Hoodoo::Utilities.deep_dup( a )
      expect( dup ).to eq( [ 1, 2, { :foo => :baz } ] )
      h[ :foo ] = :boo
      expect( dup ).to eq( [ 1, 2, { :foo => :baz } ] ) # I.e. unchanged
    end

    it 'duplicates hashes' do
      h1 = { :foo => 1 }
      h2 = { :bar => { :baz => h1 } }

      # As with arrays, make sure Ruby works as expected

      expect( h2 ).to eq( { :bar => { :baz => { :foo => 1 } } } )
      h1[ :foo ] = 2
      expect( h2 ).to eq( { :bar => { :baz => { :foo => 2 } } } )

      expect( Hoodoo::Utilities.deep_dup( h2 ) ).to eq( h2 )
      expect( Hoodoo::Utilities.deep_dup( h2 ).object_id ).to_not eq( h2.object_id )
      expect( Hoodoo::Utilities.deep_dup( h2 )[ :bar ][ :baz ].object_id ).to_not eq( h1.object_id )

      dup = Hoodoo::Utilities.deep_dup( h2 )
      expect( dup ).to eq( { :bar => { :baz => { :foo => 2 } } } )
      h1[ :foo ] = 3
      expect( dup ).to eq( { :bar => { :baz => { :foo => 2 } } } ) # I.e. unchanged
    end
  end

  describe '#deep_merge_into' do
    it 'merges hashes' do
      target_hash  = { :one => { :two => { :three => 3 } } }
      inbound_hash = { :one => { :two => { :and_four => 4 } } }
      result_hash  = Hoodoo::Utilities.deep_merge_into( target_hash, inbound_hash )

      expect( result_hash ).to eq( {
        :one => { :two => { :three => 3, :and_four => 4 } }
      } )
    end

    it 'overwrites non-Hash values at any level' do
      target_hash  = { :foo => :bar, :one => { :two => { :three => 3, :five => 5 } } }
      inbound_hash = { :foo => 'baz', :one => { :two => { :and_four => 4, :five => 'five' } } }
      result_hash  = Hoodoo::Utilities.deep_merge_into( target_hash, inbound_hash )

      expect( result_hash ).to eq( {
        :foo => 'baz', :one => { :two => { :three => 3, :and_four => 4, :five => 'five' } }
      } )
    end
  end

  describe '#hash_diff' do
    it 'works with the RDoc example code in both directions' do
      hash1 = { :foo => { :bar => 2 }, :baz => true, :boo => false }
      hash2 = { :foo => { :bar => 3 },               :boo => false }

      diff = Hoodoo::Utilities.hash_diff( hash1, hash2 )
      expect( diff ).to eq( { :foo => { :bar => [ 2, 3 ] }, :baz => [ true, nil ] } )

      diff = Hoodoo::Utilities.hash_diff( hash2, hash1 )
      expect( diff ).to eq( { :foo => { :bar => [ 3, 2 ] }, :baz => [ nil, true ] } )
    end

    it 'works when both hashes are totally mismatched' do
      hash1 = { :foo => 1 }
      hash2 = { :bar => 2 }

      diff = Hoodoo::Utilities.hash_diff( hash1, hash2 )
      expect( diff ).to eq( { :foo => [ 1, nil ], :bar => [ nil, 2 ] } )
    end

    it 'works for deep paths' do
      hash1 = { :foo => { :bar => { :baz => [ 1, 2, 3 ] } } }
      hash2 = {}

      diff = Hoodoo::Utilities.hash_diff( hash1, hash2 )
      expect( diff ).to eq( { :foo => [ { :bar => { :baz => [ 1, 2, 3 ] } }, nil ] } )
    end

    it 'works for identical hashes' do
      hash1 = { :foo => { :bar => 2 }, :baz => true, :boo => false }

      diff = Hoodoo::Utilities.hash_diff( hash1, hash1 )
      expect( diff ).to eq( {} )
    end
  end

  describe '#hash_key_paths' do
    it 'works for empty hashes' do
      hash = {}
      expect( Hoodoo::Utilities.hash_key_paths( hash ) ).to eq( [] )
    end

    it 'works for flat hashes' do
      hash = { :one => 1, :two => 2, :three => 3 }
      expect( Hoodoo::Utilities.hash_key_paths( hash ) ).to eq( [ 'one', 'two', 'three' ] )
    end

    it 'works with the RDoc example code' do
      hash = { :foo => 1, :bar => { :baz => 2, :boo => { :hello => :world } } }
      expect( Hoodoo::Utilities.hash_key_paths( hash ) ).to eq( [ 'foo', 'bar.baz', 'bar.boo.hello' ] )
    end
  end

  describe '#collated_hash_from' do
    it 'works for empty Arrays' do
      array = []
      expect( Hoodoo::Utilities.collated_hash_from( array ) ).to eq( {} )
    end

    it 'works for simple Arrays' do
      array = [ [ 'search', 'foo=bar' ], [ 'search', 'bar=baz' ] ]
      expect( Hoodoo::Utilities.collated_hash_from( array ) ).to eq( { 'search' => [ 'foo=bar', 'bar=baz' ] } )
    end

    it 'works for more complex Arrays' do
      array = [ [ :one, 1 ], [ :two, 2 ], [ :one, 42 ], [ :two , 2 ] ]
      expect( Hoodoo::Utilities.collated_hash_from( array ) ).to eq( { :one => [ 1, 42 ], :two => [ 2 ] } )
    end

    it 'allows duplicates if so asked' do
      array = [ [ :one, 1 ], [ :two, 2 ], [ :one, 42 ], [ :two , 2 ] ]
      expect( Hoodoo::Utilities.collated_hash_from( array, true ) ).to eq( { :one => [ 1, 42 ], :two => [ 2, 2 ] } )
    end
  end

  describe '#spare_port' do
    it 'should return a port number' do

      # Deeper tests happen implicitly when this call is used
      # to find real spare ports for running web server instances.
      # If it didn't work, those tests would fail (intermittently
      # or always).
      #
      expect( Hoodoo::Utilities.spare_port ).to be_a( Integer )
    end
  end

  describe 'to_integer?' do
    it 'should return integer equivalents for valid values' do
      expect(Hoodoo::Utilities.to_integer?(21)).to eq(21)
      expect(Hoodoo::Utilities.to_integer?('21')).to eq(21)
      expect(Hoodoo::Utilities.to_integer?(:'21')).to eq(21)
    end

    it 'should return nil for invalid values' do
      expect(Hoodoo::Utilities.to_integer?(2.1)).to eq(nil)
      expect(Hoodoo::Utilities.to_integer?('hello')).to eq(nil)
      expect(Hoodoo::Utilities.to_integer?(Time.now)).to eq(nil)
    end
  end
end