require 'spec_helper'

describe Hoodoo::UUID do
  before :all do
    valid_v4_full_uuids = [
    # 'xxxxxxxx-xxxx-4xxx-Yxxx-xxxxxxxxxxxx' Y = 8,9,A,B,a,b
      '01234567-89AB-4CDE-8Fab-cdef00000000',
      '01234567-89AB-4CDE-9Fab-cdef00000000',
      '01234567-89AB-4CDE-AFab-cdef00000000',
      '01234567-89AB-4CDE-BFab-cdef00000000',
      '01234567-89AB-4CDE-aFab-cdef00000000',
      '01234567-89AB-4CDE-bFab-cdef00000000'
    ]

    @valid_uuids = valid_v4_full_uuids.map { | uuid | uuid.gsub( '-', '' ) }
  end

  context '#generate' do
    it 'generates a 32 character string' do
      uuid = Hoodoo::UUID.generate()

      expect( uuid        ).to be_a( String )
      expect( uuid.length ).to eq( 32 )
    end

    it 'generates a 16 hex digit pair string' do
      uuid = Hoodoo::UUID.generate()
      expect( uuid =~ Hoodoo::UUID::MATCH_16_PAIRS_OF_HEX_DIGITS ).to_not be_nil
    end

    it 'does not generate the same UUID twice' do
      100.times do
        uuid1 = Hoodoo::UUID.generate()
        uuid2 = Hoodoo::UUID.generate()

        expect( uuid1 ).not_to eq( uuid2 )
      end
    end
  end

  context '#valid?' do
    it 'validates known-good UUIDs' do
      @valid_uuids.each do | uuid |
        expect( Hoodoo::UUID.valid?( uuid ) ).to eq( true )
      end
    end

    it 'validates internally generated UUIDs' do
      100.times do
        uuid = Hoodoo::UUID.generate()
        expect( Hoodoo::UUID.valid?( uuid ) ).to eq( true )
      end
    end

    it 'rejects non-string items' do
      uuid = Hoodoo::UUID.generate()
      expect( Hoodoo::UUID.valid?( uuid.to_sym ) ).to eq( false )
    end

    it 'rejects the wrong version check digit' do
      value = @valid_uuids.first.dup
      value[ 12 ] = '0'

      expect( Hoodoo::UUID.valid?( value ) ).to eq( false )
    end

    it 'does not match the wrong other check digit' do
      value = @valid_uuids.first.dup
      value[ 16 ] = '0'

      expect( Hoodoo::UUID.valid?( value ) ).to eq( false )
    end

    it 'does not match non-hex digits' do
      value = @valid_uuids.first.dup
      value[ 0 ] = 'Z'

      expect( Hoodoo::UUID.valid?( value ) ).to eq( false )
    end

    it 'does not match too-short strings' do
      value = @valid_uuids.first[ 0..30 ]
      expect( Hoodoo::UUID.valid?( value ) ).to eq( false )
    end

    it 'does not match too-long strings' do
      value = @valid_uuids.first + '0'
      expect( Hoodoo::UUID.valid?( value ) ).to eq( false )
    end
  end

  context 'MATCH_16_PAIRS_OF_HEX_DIGITS' do
    it 'matches 32 hex digits in any case' do
      value = '0123456789ABCDEFabcdef0123456789'
      expect( value =~ Hoodoo::UUID::MATCH_16_PAIRS_OF_HEX_DIGITS ).to_not be_nil
    end

    it 'does not match non-hex digits' do
      value = '0123456789ABCDEFabcZef0123456789'
      expect( value =~ Hoodoo::UUID::MATCH_16_PAIRS_OF_HEX_DIGITS ).to be_nil
    end

    it 'does not match too-short strings' do
      value = '0123456789ABCDEFabcdef012345678'
      expect( value =~ Hoodoo::UUID::MATCH_16_PAIRS_OF_HEX_DIGITS ).to be_nil
    end

    it 'does not match too-long strings' do
      value = '0123456789ABCDEFabcdef0123456789A'
      expect( value =~ Hoodoo::UUID::MATCH_16_PAIRS_OF_HEX_DIGITS ).to be_nil
    end
  end

  context 'MATCH_V4_UUID' do
    it 'matches known-good UUIDs' do
      @valid_uuids.each do | uuid |
        expect( uuid =~ Hoodoo::UUID::MATCH_V4_UUID ).to_not be_nil
      end
    end

    it 'does not match the wrong version check digit' do
      value = @valid_uuids.first.dup
      value[ 12 ] = '0'

      expect( value =~ Hoodoo::UUID::MATCH_V4_UUID ).to be_nil
    end

    it 'does not match the wrong other check digit' do
      value = @valid_uuids.first.dup
      value[ 16 ] = '0'

      expect( value =~ Hoodoo::UUID::MATCH_V4_UUID ).to be_nil
    end

    it 'does not match non-hex digits' do
      value = @valid_uuids.first.dup
      value[ 0 ] = 'Z'

      expect( value =~ Hoodoo::UUID::MATCH_V4_UUID ).to be_nil
    end

    it 'does not match too-short strings' do
      value = @valid_uuids.first[ 0..30 ]
      expect( value =~ Hoodoo::UUID::MATCH_V4_UUID ).to be_nil
    end

    it 'does not match too-long strings' do
      value = @valid_uuids.first + '0'
      expect( value =~ Hoodoo::UUID::MATCH_V4_UUID ).to be_nil
    end
  end
end
