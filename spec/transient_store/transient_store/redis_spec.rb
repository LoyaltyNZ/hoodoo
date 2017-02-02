require 'spec_helper'

require 'redis'
require 'hoodoo/transient_store/mocks/redis'

# ============================================================================

client = ::Redis.new( :url => 'redis://localhost:6379' )
result = client.info( 'CPU' ) rescue nil

$redis_missing = result.is_a?( Hash ) == false

backends = [ :mock ]
backends << :real unless $redis_missing

# ============================================================================

describe Hoodoo::TransientStore::Redis do

  it 'registers itself' do
    expect( Hoodoo::TransientStore.supported_storage_engines() ).to include( :redis )
  end

  if $redis_missing
    pending "*** WARNING *** Redis not present on 'redis://localhost:6379', cannot test real engine"
  end

  shared_examples 'a Redis abstraction' do | backend |

    # Either expect something on the known mock Redis instance, or an unknown
    # (any) real Redis instance. Can then call "to" - i.e. use:
    #
    #     expect_redis( backend ).to...
    #
    # +backend+:: Pass either Symbol ":mock" or ":real".
    #
    def expect_redis( backend )
      return case backend
        when :mock
          expect( @mock_redis_instance )
        else
          expect_any_instance_of( ::Redis )
      end
    end

    # ========================================================================

    before :each do
      @storage_engine_uri = 'redis://localhost:6379'

      if backend == :mock
        Hoodoo::TransientStore::Mocks::Redis.reset()
        @mock_redis_instance = Hoodoo::TransientStore::Mocks::Redis.new

        expect( ::Redis ).to(
          receive( :new ).
          with( hash_including( { :url => @storage_engine_uri } ) ).
          and_return( @mock_redis_instance )
        )
      else
        expect( ::Redis ).to(
          receive( :new ).
          with( hash_including( { :url => @storage_engine_uri } ) ).
          and_call_original()
        )
      end
    end

    # ========================================================================

    context "#initialize (#{ backend })" do
      it 'initialises' do
        instance = Hoodoo::TransientStore::Redis.new(
          storage_host_uri: @storage_engine_uri
        )

        expect( instance ).to be_a( Hoodoo::TransientStore::Redis )
      end

      it 'complains about strange Redis behaviour' do
        expect_redis( backend ).to receive( :info ).and_return( nil )

        expect {
          instance = Hoodoo::TransientStore::Redis.new(
            storage_host_uri: @storage_engine_uri
          )
        }.to raise_error(
          RuntimeError,
          "Hoodoo::TransientStore::Redis: Did not get back meaningful data from Redis at '#{ @storage_engine_uri }'"
        )
      end

      it 'handles exceptions' do
        expect_redis( backend ).to receive( :info ) do
          raise "Hello world"
        end

        expect {
          instance = Hoodoo::TransientStore::Redis.new(
            storage_host_uri: @storage_engine_uri
          )
        }.to raise_error(
          RuntimeError,
          "Hoodoo::TransientStore::Redis: Cannot connect to Redis at '#{ @storage_engine_uri }': Hello world"
        )
      end

      it 'generates expected namespaced keys' do
        instance = Hoodoo::TransientStore::Redis.new(
          storage_host_uri: @storage_engine_uri
        )

        expect( instance.send( :namespaced_key, 'foo' ) ).to eql( 'nz_co_loyalty_hoodoo_transient_store_foo' )
      end
    end

    # ========================================================================

    context "when initialised (#{ backend })" do
      before :each do
        @instance = Hoodoo::TransientStore::Redis.new(
          storage_host_uri: @storage_engine_uri
        )

        @key      = Hoodoo::UUID.generate()
        @nskey    = @instance.send( :namespaced_key, @key )
        @payload  = { 'bar' => 'baz' }
        @jpayload = JSON.fast_generate( @payload )
        @ttl      = 120
      end

      context '#set' do
        it 'sets' do
          expect_redis( backend ).to receive( :[]=    ).with( @nskey, @jpayload ).and_call_original()
          expect_redis( backend ).to receive( :expire ).with( @nskey, @ttl      ).and_call_original()

          result = @instance.set(
            key:              @key,
            payload:          @payload,
            maximum_lifespan: @ttl
          )

          expect( result ).to eq( true )
        end

        it 'allows exceptions to propagate' do
          expect_redis( backend ).to receive( :[]=    ).with( @nskey, @jpayload ) do
            raise "Hello world"
          end

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
          expect_redis( backend ).to receive( :[]=    ).with( @nskey, @jpayload ).and_call_original()
          expect_redis( backend ).to receive( :expire ).with( @nskey, @ttl      ).and_call_original()

          @instance.set(
            key:              @key,
            payload:          @payload,
            maximum_lifespan: @ttl
          )
        end

        it 'gets known keys' do
          expect_redis( backend ).to receive( :[] ).with( @nskey ).and_call_original()
          expect( @instance.get( key: @key ) ).to eql( @payload )
        end

        it 'returns "nil" for unknown keys' do
          expect( @instance.get( key: Hoodoo::UUID.generate() ) ).to be_nil
        end

        it 'allows exceptions to propagate' do
          expect_redis( backend ).to receive( :[] ).with( @nskey ) do
            raise "Hello world"
          end

          expect {
            @instance.get( key: @key )
          }.to raise_error( RuntimeError, "Hello world" )
        end
      end

      context '#delete' do
        before :each do
          expect_redis( backend ).to receive( :[]=    ).with( @nskey, @jpayload ).and_call_original()
          expect_redis( backend ).to receive( :expire ).with( @nskey, @ttl      ).and_call_original()

          @instance.set(
            key:              @key,
            payload:          @payload,
            maximum_lifespan: @ttl
          )
        end

        it 'deletes known keys' do
          expect( @instance.get( key: @key ) ).to eql( @payload )
          expect_redis( backend ).to receive( :del ).with( @nskey ).and_call_original()

          result = @instance.delete( key: @key )

          expect( result ).to eq( true )
          expect( @instance.get( key: @key ) ).to eql( nil )
        end

        it 'ignores unknown keys' do
          expect( @instance.delete( key: Hoodoo::UUID.generate() ) ).to eql( true )
        end

        it 'allows exceptions to propagate' do
          expect_redis( backend ).to receive( :del ).with( @nskey ) do
            raise "Hello world"
          end

          expect {
            @instance.delete( key: @key )
          }.to raise_error( RuntimeError, "Hello world" )
        end
      end

    end # 'context "when initialised (#{ backend })" do'
  end   # 'shared_examples ...'

  backends.each do | backend |
    it_behaves_like( 'a Redis abstraction', backend )
  end

end # 'describe...'
