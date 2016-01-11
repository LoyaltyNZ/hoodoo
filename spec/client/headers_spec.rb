require 'spec_helper'

# Full test coverage already happens "by osmosis" through "client_spec.rb" and
# the middleware suite.

describe Hoodoo::Client::Headers do
  context 'UUID_PROPERTY_PROC' do
    it 'converts valid values' do
      uuid = Hoodoo::UUID.generate()
      expect( described_class::UUID_PROPERTY_PROC.call( uuid ) ).to eq( uuid )
    end

    it 'rejects invalid values' do
      uuid = "not a UUID"
      expect( described_class::UUID_PROPERTY_PROC.call( uuid ) ).to be_nil
    end
  end

  context 'UUID_HEADER_PROC' do
    it 'converts values' do
      uuid = Hoodoo::UUID.generate()
      expect( described_class::UUID_HEADER_PROC.call( uuid ) ).to eq( uuid )
    end
  end

  context 'for URL encoded data' do
    before :each do
      @test_hash =
      {
        'foo' => "hello, world; this & that = foo! \r\t",
        'bar' => "foo;bar=baz & this + UTF-8 / emoji 😀"
      }

      @test_string = URI::encode_www_form( @test_hash )
    end

    context 'KVP_PROPERTY_PROC' do
      it 'converts valid values' do
        expect( described_class::KVP_PROPERTY_PROC.call( @test_string ) ).to eq( @test_hash )
      end

      it 'does not raise exceptions for invalid values' do
        expect( described_class::KVP_PROPERTY_PROC.call( ''      ) ).to eq( {} )
        expect( described_class::KVP_PROPERTY_PROC.call( 'hello' ) ).to eq( { 'hello' => '' } )
      end
    end

    context 'KVP_HEADER_PROC' do
      it 'converts values' do
        expect( described_class::KVP_HEADER_PROC.call( @test_hash ) ).to eq( @test_string )
      end
    end
  end

  context 'DATETIME_IN_PAST_ONLY_PROPERTY_PROC' do
    it 'converts valid values' do
      date_time = DateTime.now - 10.seconds
      date_time_str = Hoodoo::Utilities.nanosecond_iso8601( date_time )
      expect( described_class::DATETIME_IN_PAST_ONLY_PROPERTY_PROC.call( date_time_str ) ).to eq( date_time )
    end

    context 'rejects invalid values' do
      it 'that are not date/times' do
        date_time_str = 'not a date/time'
        expect( described_class::DATETIME_IN_PAST_ONLY_PROPERTY_PROC.call( date_time_str ) ).to be_nil
      end

      it 'that are Ruby-valid but not in supported ISO 8601 subset format' do
        date_time_str = Time.now.to_s
        expect( described_class::DATETIME_IN_PAST_ONLY_PROPERTY_PROC.call( date_time_str ) ).to be_nil
      end

      it 'that are valid but in the future' do
        date_time = DateTime.now + 1.hour
        date_time_str = Hoodoo::Utilities.nanosecond_iso8601( date_time )
        expect( described_class::DATETIME_IN_PAST_ONLY_PROPERTY_PROC.call( date_time_str ) ).to be_nil
      end
    end
  end

  it 'DATETIME_WRITER_PROC calls rationalisation method' do
    now = Time.now
    expect( Hoodoo::Utilities ).to receive( :rationalise_datetime ).once.with( now ).and_call_original
    expect( described_class::DATETIME_WRITER_PROC.call( now ) ).to eq( now.to_datetime )
  end

  context 'DATETIME_HEADER_PROC converts values' do
    it 'that are DateTime instances' do
      date_time = DateTime.now - 10.seconds
      date_time_str = Hoodoo::Utilities.nanosecond_iso8601( date_time )
      expect( described_class::DATETIME_HEADER_PROC.call( date_time ) ).to eq( date_time_str )
    end

    # Technically undocumented but highly likely to happen by accident and
    # the Proc is written using the Hoodoo::Utilities support methods so
    # this should always work.
    #
    it 'that are Time instances' do
      time = Time.now - 10.seconds
      time_str = Hoodoo::Utilities.nanosecond_iso8601( time )
      expect( described_class::DATETIME_HEADER_PROC.call( time ) ).to eq( time_str )
    end
  end

  context 'BOOLEAN_PROPERTY_PROC converts values' do
    it 'that are yes/no' do
      expect( described_class::BOOLEAN_PROPERTY_PROC.call( 'yes' ) ).to eq( true  )
      expect( described_class::BOOLEAN_PROPERTY_PROC.call( 'Yes' ) ).to eq( true  )
      expect( described_class::BOOLEAN_PROPERTY_PROC.call( 'YES' ) ).to eq( true  )
      expect( described_class::BOOLEAN_PROPERTY_PROC.call( 'no'  ) ).to eq( false )
      expect( described_class::BOOLEAN_PROPERTY_PROC.call( 'No'  ) ).to eq( false )
      expect( described_class::BOOLEAN_PROPERTY_PROC.call( 'NO'  ) ).to eq( false )
    end

    it 'that are not yes/no' do
      expect( described_class::BOOLEAN_PROPERTY_PROC.call( nil     ) ).to eq( false )
      expect( described_class::BOOLEAN_PROPERTY_PROC.call( ''      ) ).to eq( false )
      expect( described_class::BOOLEAN_PROPERTY_PROC.call( 'Yess'  ) ).to eq( false )
      expect( described_class::BOOLEAN_PROPERTY_PROC.call( 'oui'   ) ).to eq( false )
      expect( described_class::BOOLEAN_PROPERTY_PROC.call( 'true'  ) ).to eq( false )
    end
  end

  context 'BOOLEAN_HEADER_PROC converts values' do
    it 'that are true/false' do
      expect( described_class::BOOLEAN_HEADER_PROC.call( true   ) ).to eq( 'yes' )
      expect( described_class::BOOLEAN_HEADER_PROC.call( false  ) ).to eq( 'no' )
    end

    it 'that are not true/false' do
      expect( described_class::BOOLEAN_HEADER_PROC.call( nil    ) ).to eq( 'no' )
      expect( described_class::BOOLEAN_HEADER_PROC.call( 'yes'  ) ).to eq( 'no' )
      expect( described_class::BOOLEAN_HEADER_PROC.call( 'true' ) ).to eq( 'no' )
    end
  end

  context 'HEADER_TO_PROPERTY' do
    it 'contains the minimum required properties for all descriptions' do
      expect( described_class::HEADER_TO_PROPERTY.keys.size ).to_not eq( 0 )

      described_class::HEADER_TO_PROPERTY.each do | rack_header, description |
        expect( rack_header[ 0..6 ] ).to eq( 'HTTP_X_' )

        expect( description[ :property        ] ).to_not be_nil
        expect( description[ :property_writer ] ).to     eq( "#{ description[ :property ] }=" )
        expect( description[ :property_writer ] ).to_not eq( '=' )
        expect( description[ :property_proc   ] ).to     be_a( Proc )
        expect( description[ :header          ] ).to_not be_nil
        expect( description[ :header_proc     ] ).to     be_a( Proc )
      end
    end
  end

  # Slightly weak but test coverage for the varied bespoke property writers
  # - which have individual requirements on data types and so-on - gets
  # brought in by all the other tests which explicitly check that headers
  # in the HEADER_TO_PROPERTY set are working properly. In the end, it all
  # gets proper coverage.
  #
  context '#define_accessors_for_header_equivalents' do
    class RSpecDefineAccessorsForHeaderEquivalentsTest
    end

    before :all do
      described_class.define_accessors_for_header_equivalents( RSpecDefineAccessorsForHeaderEquivalentsTest )
      @instance = RSpecDefineAccessorsForHeaderEquivalentsTest.new
    end

    it 'defines read accessors' do
      described_class::HEADER_TO_PROPERTY.each do | rack_header, description |
        method = description[ :property ]
        expect( @instance ).to respond_to( method )
      end
    end

    it 'defines write accessors' do
      described_class::HEADER_TO_PROPERTY.each do | rack_header, description |
        method = description[ :property_writer ]
        expect( @instance ).to respond_to( method )
      end
    end
  end

  context '#x_header_to_options' do
    it 'converts headers' do
      hash = {
        'x-interaction-id'      => '23',
        'X-Foo-Bar'             => '42',
        'x_underscored_item'    => 'hello world',
        'X_CAPITAL_UNDERSCORES' => 'yes'
      }

      options = Hoodoo::Client::Headers.x_header_to_options( hash )

      expect( options[ 'interaction_id'      ] ).to eq( '23'          )
      expect( options[ 'foo_bar'             ] ).to eq( '42'          )
      expect( options[ 'underscored_item'    ] ).to eq( 'hello world' )
      expect( options[ 'capital_underscores' ] ).to eq( 'yes'         )
    end
  end
end
