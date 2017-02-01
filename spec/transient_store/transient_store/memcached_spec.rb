require 'spec_helper'
require 'dalli'

# ============================================================================

old_level          = Dalli.logger.level
Dalli.logger.level = Logger::ERROR
client             = ::Dalli::Client.new( 'localhost:11211' )
result             = begin; client.stats; rescue; nil; end
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

    @backend = backend

    # Either expect something on the known mock Dalli instance, or an unknown
    # (any) real Dalli::Client instance. Can then call "to" - i.e. use:
    #
    #     expect_dalli.to...
    #
    def expect_dalli
      return case @backend
        when :mock
          expect( @mock_dalli_instance )
        else
          expect_any_instance_of( ::Dalli::Client )
      end
    end

    # ========================================================================

    before :each do
      @storage_engine_uri = 'localhost:11211'

      if @backend == :mock
        Hoodoo::Services::Session::MockDalliClient.reset()
        @mock_dalli_instance = Hoodoo::Services::Session::MockDalliClient.new

        expect( ::Dalli::Client ).to(
          receive( :new ).
          with(
            @storage_engine_uri,
            hash_including( { :namespace => :nz_co_loyalty_hoodoo_transient_store_ } )
          ).
          and_return( @mock_dalli_instance )
        )
      else
        expect( ::Dalli::Client ).to(
          receive( :new ).
          with(
            @storage_engine_uri,
            hash_including( { :namespace => :nz_co_loyalty_hoodoo_transient_store_ } )
          ).
          and_call_original()
        )
      end
    end

    # ========================================================================

    context "#initialize (#{ @backend })" do
      it 'initialises' do
        instance = Hoodoo::TransientStore::Memcached.new(
          storage_host_uri: @storage_engine_uri
        )
      end

      it 'complains about strange Memcached behaviour' do
        expect_dalli.to receive( :stats ).and_return( nil )

        expect {
          instance = Hoodoo::TransientStore::Memcached.new(
            storage_host_uri: @storage_engine_uri
          )
        }.to raise_error(
          RuntimeError,
          "Hoodoo::TransientStore::Memcached: Did not get back meaningful data from Memcached at '#{ @storage_engine_uri }'"
        )
      end

      it 'handles exceptions' do
        expect_dalli.to receive( :stats ) do
          raise "Hello world"
        end

        expect {
          instance = Hoodoo::TransientStore::Memcached.new(
            storage_host_uri: @storage_engine_uri
          )
        }.to raise_error(
          RuntimeError,
          "Hoodoo::TransientStore::Memcached: Cannot connect to Memcached at '#{ @storage_engine_uri }': Hello world"
        )
      end
    end

    # ========================================================================

    context "when initialised (#{ @backend })" do
      before :each do
        @key      = Hoodoo::UUID.generate()
        @payload  = { 'bar' => 'baz' }
        @ttl      = 120
        @instance = Hoodoo::TransientStore::Memcached.new(
          storage_host_uri: @storage_engine_uri
        )
      end

      context '#set' do
        it 'sets' do
          expect_dalli.to receive( :set ).with( @key, @payload, @ttl ).and_call_original()

          @instance.set(
            key:              @key,
            payload:          @payload,
            maximum_lifespan: @ttl
          )
        end

        it 'allows exceptions to propagate' do
          expect_dalli.to receive( :set ).with( @key, @payload, @ttl ) do
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
          expect_dalli.to receive( :set ).with( @key, @payload, @ttl ).and_call_original()

          @instance.set(
            key:              @key,
            payload:          @payload,
            maximum_lifespan: @ttl
          )
        end

        it 'gets known keys' do
          expect_dalli.to receive( :get ).with( @key ).and_call_original()
          expect( @instance.get( key: @key ) ).to eql( @payload )
        end

        it 'returns "nil" for unknown keys' do
          expect( @instance.get( key: Hoodoo::UUID.generate() ) ).to be_nil
        end

        it 'allows exceptions to propagate' do
          expect_dalli.to receive( :get ).with( @key ) do
            raise "Hello world"
          end

          expect {
            @instance.get( key: @key )
          }.to raise_error( RuntimeError, "Hello world" )
        end
      end

      context '#delete' do
        before :each do
          expect_dalli.to receive( :set ).with( @key, @payload, @ttl ).and_call_original()

          @instance.set(
            key:              @key,
            payload:          @payload,
            maximum_lifespan: @ttl
          )
        end

        it 'deletes known keys' do
          expect( @instance.get( key: @key ) ).to eql( @payload )
          expect_dalli.to receive( :delete ).with( @key ).and_call_original()
          @instance.delete( key: @key )
          expect( @instance.get( key: @key ) ).to eql( nil )
        end

        it 'ignores unknown keys' do
          expect {
            @instance.delete( key: Hoodoo::UUID.generate() )
          }.to_not raise_error
        end

        it 'allows exceptions to propagate' do
          expect_dalli.to receive( :delete ).with( @key ) do
            raise "Hello world"
          end

          expect {
            @instance.delete( key: @key )
          }.to raise_error( RuntimeError, "Hello world" )
        end
      end

    end # 'context "when initialised (#{ @backend })" do'
  end   # 'shared_examples ...'

  backends.each do | backend |
    it_behaves_like( 'a Memcached abstraction', backend )
  end

end # 'describe...'
