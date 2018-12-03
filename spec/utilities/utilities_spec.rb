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

  describe '#to_integer?' do
    it 'should return integer equivalents for valid values' do
      expect( Hoodoo::Utilities.to_integer?( 21    ) ).to eq( 21 )
      expect( Hoodoo::Utilities.to_integer?( '21'  ) ).to eq( 21 )
      expect( Hoodoo::Utilities.to_integer?( :'21' ) ).to eq( 21 )
    end

    it 'should return nil for invalid values' do
      expect( Hoodoo::Utilities.to_integer?( 2.1      ) ).to eq( nil )
      expect( Hoodoo::Utilities.to_integer?( 'hello'  ) ).to eq( nil )
      expect( Hoodoo::Utilities.to_integer?( Time.now ) ).to eq( nil )
    end
  end

  # Much of this is similar at the time of writing to the code in
  # types/date_time_spec.rb, but kept here as independent tests in
  # case the DateTime type code stops calling the Utility validation
  # code in future for any reason.
  #
  describe '#valid_iso8601_subset_datetime?' do
    it 'accepts valid' do
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2014-12-11T00:00:00Z'           ) ).to be_a( DateTime )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2012-02-29T00:00:00Z'           ) ).to be_a( DateTime )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2012-02-29T00:00:00.0Z'         ) ).to be_a( DateTime )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2012-02-29T00:00:00.0000Z'      ) ).to be_a( DateTime )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2012-02-29T00:00:00.000000000Z' ) ).to be_a( DateTime )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2012-02-29T00:00:00+12:30'      ) ).to be_a( DateTime )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2012-02-29T00:00:00-12:30'      ) ).to be_a( DateTime )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2012-02-29T00:00:00.0+12:30'    ) ).to be_a( DateTime )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2012-02-29T00:00:00.0-12:30'    ) ).to be_a( DateTime )
    end

    it 'rejects invalid' do
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2014-12-11T12:12:61Z' ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2014-12-11T12:60:00Z' ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2014-12-11T25:00:00Z' ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2014-02-29T00:00:00Z' ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2014-13-01T00:00:00Z' ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2014-99-99T00:00:00Z' ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( 'asckn'                ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( '2014-12-11'           ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( 34534.234              ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( 38247                  ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( true                   ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( DateTime.now           ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( {}                     ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_datetime?( []                     ) ).to eq( false )
    end
  end

  # Much of this is similar at the time of writing to the code in
  # types/date_spec.rb, but kept here as independent tests in case
  # the Date type code stops calling the Utility validation code
  # in future for any reason.
  #
  describe '#valid_iso8601_subset_date?' do
    it 'accepts valid' do
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( '2014-12-11' ) ).to be_a( Date )
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( '2012-02-29' ) ).to be_a( Date )
    end

    it 'rejects invalid' do
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( '2014-02-29'           ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( '2014-13-01'           ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( '2014-99-99'           ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( 'asckn'                ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( '2014-12-11T00:00:00Z' ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( 34534.234              ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( 38247                  ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( true                   ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( Date.today             ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( {}                     ) ).to eq( false )
      expect( Hoodoo::Utilities.valid_iso8601_subset_date?( []                     ) ).to eq( false )
    end
  end

  describe '#is_in_future?' do
    before :each do
      @old_drift = ENV[ 'HOODOO_CLOCK_DRIFT_TOLERANCE' ]
      ENV.delete( 'HOODOO_CLOCK_DRIFT_TOLERANCE' )
      Hoodoo::Utilities.clear_clock_drift_configuration_cache!

      @default = 30
    end

    after :all do
      ENV[ 'HOODOO_CLOCK_DRIFT_TOLERANCE' ] = @old_drift
    end

    context 'when comparing to now' do
      it 'says "no" for "now"' do
        expect( Hoodoo::Utilities.is_in_future?( Time.now ) ).to eq( false )
      end

      it 'says "no" inside default drift allowance' do
        expect( Hoodoo::Utilities.is_in_future?( Time.now + ( @default / 2 ) ) ).to eq( false )
      end

      # Hoodoo Guides: "...less than or equal to... ...is permitted...".
      #
      it 'says "no" at default drift allowance' do
        expect( Hoodoo::Utilities.is_in_future?( Time.now + @default ) ).to eq( false )
      end

      it 'says "yes" outside default drift allowance' do
        expect( Hoodoo::Utilities.is_in_future?( Time.now + @default + 1 ) ).to eq( true )
      end
    end

    context 'when comparing to a date in the past' do

      before(:each) do
        @past_date = Time.now - ( @default * 2 )
      end

      it 'says "yes" for "now"' do
        expect( Hoodoo::Utilities.is_in_future?( Time.now, @past_date ) ).to eq( true )
      end

      it 'says "no" inside default drift allowance' do
        expect( Hoodoo::Utilities.is_in_future?( @past_date + ( @default / 2 ), @past_date ) ).to eq( false )
      end

      it 'says "no" at default drift allowance' do
        expect( Hoodoo::Utilities.is_in_future?( @past_date + @default, @past_date ) ).to eq( false )
      end

      it 'says "yes" outside default drift allowance' do
        expect( Hoodoo::Utilities.is_in_future?( @past_date + @default + 1, @past_date ) ).to eq( true )
      end
    end

    context 'when comparing to a date in the future' do

      before(:each) do
        @future_date = Time.now + ( @default * 2 )
      end

      it 'says "no" for "now"' do
        expect( Hoodoo::Utilities.is_in_future?( Time.now, @future_date ) ).to eq( false )
      end

      it 'says "no" for a date before the future date, but after "now"' do
        expect( Hoodoo::Utilities.is_in_future?( Time.now + ( @default / 2 ), @future_date ) ).to eq( false )
      end

      it 'says "no" inside default drift allowance' do
        expect( Hoodoo::Utilities.is_in_future?( @future_date + ( @default / 2 ), @future_date ) ).to eq( false )
      end

      it 'says "no" at default drift allowance' do
        expect( Hoodoo::Utilities.is_in_future?( @future_date + @default, @future_date ) ).to eq( false )
      end

      it 'says "yes" outside default drift allowance' do
        expect( Hoodoo::Utilities.is_in_future?( @future_date + @default + 1, @future_date ) ).to eq( true )
      end
    end

    it 'drift allowance can be reconfigured' do
      spec_helper_change_environment( 'HOODOO_CLOCK_DRIFT_TOLERANCE', '10' ) do
        Hoodoo::Utilities.clear_clock_drift_configuration_cache!
        expect( Hoodoo::Utilities.is_in_future?( Time.now + 10 ) ).to eq( false )
        expect( Hoodoo::Utilities.is_in_future?( Time.now + 11 ) ).to eq( true )
      end
    end

    it 'drift allowance can be set to zero' do
      spec_helper_change_environment( 'HOODOO_CLOCK_DRIFT_TOLERANCE', '0' ) do
        Hoodoo::Utilities.clear_clock_drift_configuration_cache!
        expect( Hoodoo::Utilities.is_in_future?( Time.now ) ).to eq( false )
        expect( Hoodoo::Utilities.is_in_future?( Time.now + 0.1 ) ).to eq( true )
      end
    end

    it 'drift configuration is cached' do
      expect( Hoodoo::Utilities.is_in_future?( Time.now + @default + 1 ) ).to eq( true )

      # Configuring the environment variable for a much longer tolerance
      # without resetting the internal cache variable should result in
      # the old value still being used.
      #
      spec_helper_change_environment( 'HOODOO_CLOCK_DRIFT_TOLERANCE', ( @default * 2 ).to_s ) do
        expect( Hoodoo::Utilities.is_in_future?( Time.now + @default + 1 ) ).to eq( true )
      end
    end
  end

  describe '#standard_iso8601' do
    before :each do
      @old_tz = ENV[ 'TZ' ]
      ENV[ 'TZ' ] = 'EST'
    end

    after :each do
      @old_tz.blank? ? ENV.delete( 'TZ' ) : ENV[ 'TZ' ] = @old_tz
    end

    it 'accepts a non-UTC Time and renders a UTC date-time' do
      now = Time.new( 2017, 7, 28, 8, 41, 15 ) + 0.123456789
      iso = now.utc.iso8601( 6 )

      expect( Hoodoo::Utilities.standard_datetime( now ) ).to eq( iso )
    end

    it 'accepts a non-UTC Date and renders a UTC date-time' do
      now = Date.new( 2017, 7, 28 )
      iso = now.to_time.utc.iso8601( 6 )

      expect( Hoodoo::Utilities.standard_datetime( now ) ).to eq( iso )
    end

    it 'accepts a non-UTC DateTime and renders a UTC date-time' do
      now = DateTime.new( 2017, 7, 28, 8, 41, 15 ) + 0.123456789
      iso = now.to_time.utc.iso8601( 6 )

      expect( Hoodoo::Utilities.standard_datetime( now ) ).to eq( iso )
    end
  end

  describe '#nanosecond_iso8601' do
    it 'should convert DateTime to a nanosecond precision String' do
      now  = DateTime.now()
      iso  = now.iso8601( 9 )

      expect( Hoodoo::Utilities.nanosecond_iso8601( now ) ).to eq( iso )
    end

    it 'should convert Time to a nanosecond precision String' do
      now  = Time.now()
      iso  = now.iso8601( 9 )

      expect( Hoodoo::Utilities.nanosecond_iso8601( now ) ).to eq( iso )
    end
  end

  describe '#rationalise_datetime' do
    it 'accepts and returns nil' do
      expect( Hoodoo::Utilities.rationalise_datetime( nil ) ).to eq( nil )
    end

    it 'accepts and returns a DateTime' do
      now = DateTime.now
      expect( Hoodoo::Utilities.rationalise_datetime( now ) ).to eq( now )
    end

    it 'accepts a Time and returns a DateTime' do
      now = Time.now
      expect( Hoodoo::Utilities.rationalise_datetime( now ) ).to eq( now.to_datetime )
    end

    it 'accepts a Date and returns a DateTime' do
      now = Date.today
      expect( Hoodoo::Utilities.rationalise_datetime( now ) ).to eq( now.to_datetime )
    end

    # If this fails your system might report time to beyond-nanosecond
    # precision, so the str-to-DateTime result mismatches the original
    # DateTime in the fractional seconds.
    #
    it 'accepts a parseable String and returns a DateTime' do
      now = DateTime.now
      str = Hoodoo::Utilities.nanosecond_iso8601( now )
      expect( Hoodoo::Utilities.rationalise_datetime( str ) ).to eq( now )
    end

    it 'rejects invalid input with an exception' do
      expect {
        Hoodoo::Utilities.rationalise_datetime( "hello" )
      }.to raise_exception

      expect {
        Hoodoo::Utilities.rationalise_datetime( Array.new )
      }.to raise_exception
    end
  end
end
