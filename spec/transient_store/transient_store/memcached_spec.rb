require 'spec_helper'

require 'dalli'
require 'hoodoo/transient_store/mocks/dalli_client'

# ============================================================================

old_level          = Dalli.logger.level
Dalli.logger.level = Logger::ERROR
client             = ::Dalli::Client.new( 'localhost:11211' )
result             = client.stats() rescue nil
Dalli.logger.level = old_level
$memcached_missing = result.is_a?( Hash ) == false || result[ 'localhost:11211' ].nil?

backends = [ :mock ]
backends << :real unless $memcached_missing

# ============================================================================

describe Hoodoo::TransientStore::Memcached do
  before :all do
    @old_level         = Dalli.logger.level
    Dalli.logger.level = Logger::ERROR
  end

  after :all do
    Dalli.logger.level = @old_level
  end

  it 'registers itself' do
    expect( Hoodoo::TransientStore.supported_storage_engines() ).to include( :memcached )
  end

  if $memcached_missing
    pending "*** WARNING *** Memcached not present on 'localhost:11211', cannot test real engine"
  end

  shared_examples 'a Memcached abstraction' do | backend |

    # Either expect something on the known mock backend instance or an unknown
    # (any) real Dalli::Client instance. Can then call "to" - i.e. use:
    #
    #     expect_dalli_client( backend ).to...
    #
    # +backend+:: Pass either Symbol ":mock" or ":real".
    #
    def expect_dalli_client( backend )
      return case backend
        when :mock
          expect( @mock_dalli_client_instance )
        else
          expect_any_instance_of( ::Dalli::Client )
      end
    end

    # ========================================================================

    before :each do
      @storage_engine_uri = 'localhost:11211'
      @namespace          = Hoodoo::UUID.generate()

      if backend == :mock
        Hoodoo::TransientStore::Mocks::DalliClient.reset()
        @mock_dalli_client_instance = Hoodoo::TransientStore::Mocks::DalliClient.new

        expect( ::Dalli::Client ).to(
          receive( :new ).
          with(
            @storage_engine_uri,
            hash_including( { :namespace => @namespace } )
          ).
          and_return( @mock_dalli_client_instance )
        )
      else
        expect( ::Dalli::Client ).to(
          receive( :new ).
          with(
            @storage_engine_uri,
            hash_including( { :namespace => @namespace } )
          ).
          and_call_original()
        )
      end
    end

    # ========================================================================

    context "#initialize (#{ backend })" do
      it 'initialises' do
        instance = Hoodoo::TransientStore::Memcached.new(
          storage_host_uri: @storage_engine_uri,
          namespace:        @namespace
        )

        expect( instance ).to be_a( Hoodoo::TransientStore::Memcached )
      end

      it 'complains about strange Memcached behaviour' do
        expect_dalli_client( backend ).to receive( :stats ).and_return( nil )

        expect {
          instance = Hoodoo::TransientStore::Memcached.new(
            storage_host_uri: @storage_engine_uri,
            namespace:        @namespace
          )
        }.to raise_error(
          RuntimeError,
          "Hoodoo::TransientStore::Memcached: Did not get back meaningful data from Memcached at '#{ @storage_engine_uri }'"
        )
      end

      it 'handles exceptions' do
        expect_dalli_client( backend ).to receive( :stats ).and_raise( 'Hello world' )

        expect {
          instance = Hoodoo::TransientStore::Memcached.new(
            storage_host_uri: @storage_engine_uri,
            namespace:        @namespace
          )
        }.to raise_error(
          RuntimeError,
          "Hoodoo::TransientStore::Memcached: Cannot connect to Memcached at '#{ @storage_engine_uri }': Hello world"
        )
      end
    end

    # ========================================================================

    context "when initialised (#{ backend })" do
      before :each do
        @instance = Hoodoo::TransientStore::Memcached.new(
          storage_host_uri: @storage_engine_uri,
          namespace:        @namespace
        )

        @key      = Hoodoo::UUID.generate()
        @payload  = { 'bar' => 'baz' }
        @ttl      = 120
      end

      context '#set' do
        it 'sets' do
          expect_dalli_client( backend ).to receive( :set ).with( @key, @payload, @ttl ).and_call_original()

          result = @instance.set(
            key:              @key,
            payload:          @payload,
            maximum_lifespan: @ttl
          )

          expect( result ).to eq( true )
        end

        it 'allows exceptions to propagate' do
          expect_dalli_client( backend ).to receive( :set ).with( @key, @payload, @ttl ).and_raise( 'Hello world' )

          expect {
            @instance.set(
              key:              @key,
              payload:          @payload,
              maximum_lifespan: @ttl
            )
          }.to raise_error( RuntimeError, "Hello world" )
        end
      end

      context '#get' do
        before :each do
          expect_dalli_client( backend ).to receive( :set ).with( @key, @payload, @ttl ).and_call_original()

          @instance.set(
            key:              @key,
            payload:          @payload,
            maximum_lifespan: @ttl
          )
        end

        it 'gets known keys' do
          expect_dalli_client( backend ).to receive( :get ).with( @key ).and_call_original()
          expect( @instance.get( key: @key ) ).to eql( @payload )
        end

        it 'returns "nil" for unknown keys' do
          expect( @instance.get( key: Hoodoo::UUID.generate() ) ).to be_nil
        end

        it 'allows exceptions to propagate' do
          expect_dalli_client( backend ).to receive( :get ).with( @key ).and_raise( 'Hello world' )

          expect {
            @instance.get( key: @key )
          }.to raise_error( RuntimeError, "Hello world" )
        end
      end

      context '#delete' do
        before :each do
          expect_dalli_client( backend ).to receive( :set ).with( @key, @payload, @ttl ).and_call_original()

          @instance.set(
            key:              @key,
            payload:          @payload,
            maximum_lifespan: @ttl
          )
        end

        it 'deletes known keys' do
          expect( @instance.get( key: @key ) ).to eql( @payload )
          expect_dalli_client( backend ).to receive( :delete ).with( @key ).and_call_original()

          result = @instance.delete( key: @key )

          expect( result ).to eq( true )
          expect( @instance.get( key: @key ) ).to eql( nil )
        end

        it 'ignores unknown keys' do
          expect( @instance.delete( key: Hoodoo::UUID.generate() ) ).to eql( true )
        end

        it 'allows exceptions to propagate' do
          expect_dalli_client( backend ).to receive( :delete ).with( @key ).and_raise( 'Hello world' )

          expect {
            @instance.delete( key: @key )
          }.to raise_error( RuntimeError, "Hello world" )
        end
      end

      context 'close' do
        it 'closes' do
          expect_dalli_client( backend ).to receive( :close )
          @instance.close()
        end
      end

    end # 'context "when initialised (#{ backend })" do'
  end   # 'shared_examples ...'

  backends.each do | backend |
    it_behaves_like( 'a Memcached abstraction', backend )
  end

end # 'describe...'
