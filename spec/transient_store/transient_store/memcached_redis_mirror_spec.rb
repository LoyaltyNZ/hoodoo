require 'spec_helper'

require 'hoodoo/transient_store/mocks/dalli_client'
require 'hoodoo/transient_store/mocks/redis'

# These tests make sure that the mirror class calls down to the Memcached and
# Redis abstractions, but assumes those abstractions are thoroughly tested by
# their own unit tests. So it makes sure it gets expected call and result
# behaviour, but doesn't worry about mock or real Redis and so-on.
#
describe Hoodoo::TransientStore::MemcachedRedisMirror do

  it 'registers itself' do
    expect( Hoodoo::TransientStore.supported_storage_engines() ).to include( :memcached_redis_mirror )
  end

  before :each do
    @memcached_uri      = 'localhost:11211'
    @redis_uri          = 'redis://localhost:6379'
    @storage_engine_uri = {
      :memcached => @memcached_uri,
      :redis     => @redis_uri
    }

    # Use pure mock back-ends behind the Memcached and Redis abstraction
    # layers; real back-end tests are done for them in their unit tests.

    Hoodoo::TransientStore::Mocks::DalliClient.reset()
    Hoodoo::TransientStore::Mocks::Redis.reset()

    allow( Dalli::Client ).to(
      receive( :new ).
      and_return( Hoodoo::TransientStore::Mocks::DalliClient.new )
    )

    allow( Redis ).to(
      receive( :new ).
      and_return( Hoodoo::TransientStore::Mocks::Redis.new )
    )

    @instance = Hoodoo::TransientStore::MemcachedRedisMirror.new(
      storage_host_uri: @storage_engine_uri
    )
  end

  # ==========================================================================

  context '#initialize' do
    it 'initialises' do
      expect( @instance ).to be_a( Hoodoo::TransientStore::MemcachedRedisMirror )
    end

    it 'complains about bad parameters' do
      expect {
        Hoodoo::TransientStore::MemcachedRedisMirror.new(
          storage_host_uri: 'some string'
        )
      }.to raise_error( RuntimeError, 'Hoodoo::TransientStore::MemcachedRedisMirror: Bad storage host URI data passed to constructor' )

      expect {
        Hoodoo::TransientStore::MemcachedRedisMirror.new(
          storage_host_uri: { :hash => 'without required keys' }
        )
      }.to raise_error( RuntimeError, 'Hoodoo::TransientStore::MemcachedRedisMirror: Bad storage host URI data passed to constructor' )
    end

    it 'creates Memcached and Redis instances' do
      expect( Hoodoo::TransientStore::Memcached ).to receive( :new )
      expect( Hoodoo::TransientStore::Redis     ).to receive( :new )

      Hoodoo::TransientStore::MemcachedRedisMirror.new(
        storage_host_uri: @storage_engine_uri
      )
    end
  end

  # ==========================================================================

  context 'when initialised' do
    before :each do
      @key      = Hoodoo::UUID.generate()
      @payload  = { 'bar' => 'baz' }
      @ttl      = 120
    end

    context '#set' do
      it 'sets' do
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :set ).with( key: @key, payload: @payload, maximum_lifespan: @ttl ).and_call_original()
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :set ).with( key: @key, payload: @payload, maximum_lifespan: @ttl ).and_call_original()

        result = @instance.set(
          key:              @key,
          payload:          @payload,
          maximum_lifespan: @ttl
        )

        expect( result ).to eq( true )
      end

      it 'allows Memcached exceptions to propagate' do
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :set ) do
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

      it 'allows Redis exceptions to propagate' do
        expect_any_instance_of( Hoodoo::TransientStore::Redis ).to receive( :set ) do
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
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :set ).with( key: @key, payload: @payload, maximum_lifespan: @ttl ).and_call_original()
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :set ).with( key: @key, payload: @payload, maximum_lifespan: @ttl ).and_call_original()

        @instance.set(
          key:              @key,
          payload:          @payload,
          maximum_lifespan: @ttl
        )
      end

      it 'gets known keys' do
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :get ).with( key: @key ).and_call_original()
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :get ).with( key: @key ).and_call_original()

        expect( @instance.get( key: @key ) ).to eql( @payload )
      end

      it 'returns "nil" for unknown keys' do
        expect( @instance.get( key: Hoodoo::UUID.generate() ) ).to be_nil
      end

      it 'returns "nil" if Memcached is missing the data' do
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :get ).with( key: @key ).and_return( nil )
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :get ).with( key: @key ).and_call_original()

        expect( @instance.get( key: @key ) ).to be_nil
      end

      it 'returns "nil" if Redis is missing the data' do
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :get ).with( key: @key ).and_call_original()
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :get ).with( key: @key ).and_return( nil )

        expect( @instance.get( key: @key ) ).to be_nil
      end

      it 'allows Memcached exceptions to propagate' do
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :get ) do
          raise "Hello world"
        end

        expect {
          @instance.get( key: @key )
        }.to raise_error( RuntimeError, "Hello world" )
      end

      it 'allows Redis exceptions to propagate' do
        expect_any_instance_of( Hoodoo::TransientStore::Redis ).to receive( :get ) do
          raise "Hello world"
        end

        expect {
          @instance.get( key: @key )
        }.to raise_error( RuntimeError, "Hello world" )
      end

      context 'with migration selector of' do
        context ':both' do
          it 'is the default' do
            expect( @instance.get_keys_from ).to eql( :both )
          end

          # This is covered elsewhere too but belt-and-braces checks don't hurt
          # and the test list looks cleaner when this one section covers all
          # allowed values of the selector.

          it 'returns data if the key is in both engines' do
            expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :get ).with( key: @key ).and_call_original()
            expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :get ).with( key: @key ).and_call_original()

            expect( @instance.get( key: @key ) ).to eql( @payload )
          end

          it 'returns "nil" if the key is only in Memcached' do
            expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :get ).with( key: @key ).and_call_original()
            expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :get ).with( key: @key ).and_return( nil )

            expect( @instance.get( key: @key ) ).to be_nil
          end

          it 'returns "nil" if the key is only in Redis' do
            expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :get ).with( key: @key ).and_return( nil )
            expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :get ).with( key: @key ).and_call_original()

            expect( @instance.get( key: @key ) ).to be_nil
          end
        end

        context ':memcached' do
          before( :each ) { @instance.get_keys_from = :memcached }
           after( :each ) { @instance.get_keys_from = :both  }

          it 'returns data if the key is in both engines' do
            expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to     receive( :get ).with( key: @key ).and_call_original()
            expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to_not receive( :get )

            expect( @instance.get( key: @key ) ).to eql( @payload )
          end

          it 'returns data if the key is only in Memcached' do
            expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to     receive( :get ).with( key: @key ).and_call_original()
            expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to_not receive( :get )

            expect( @instance.get( key: @key ) ).to eql( @payload )
          end

          it 'returns "nil" if the key is only in Redis' do
            expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to     receive( :get ).with( key: @key ).and_return( nil )
            expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to_not receive( :get )

            expect( @instance.get( key: @key ) ).to be_nil
          end
        end

        context ':redis' do
          before( :each ) { @instance.get_keys_from = :redis }
           after( :each ) { @instance.get_keys_from = :both  }

          it 'returns data if the key is in both engines' do
            expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to_not receive( :get )
            expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to     receive( :get ).with( key: @key ).and_call_original()

            expect( @instance.get( key: @key ) ).to eql( @payload )
          end

          it 'returns "nil" if the key is only in Memcached' do
            expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to_not receive( :get )
            expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to     receive( :get ).with( key: @key ).and_return( nil )

            expect( @instance.get( key: @key ) ).to be_nil
          end

          it 'returns data if the key is only in Redis' do
            expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to_not receive( :get )
            expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to     receive( :get ).with( key: @key ).and_call_original()

            expect( @instance.get( key: @key ) ).to eql( @payload )
          end
        end

        context 'an unrecognised value' do
          before( :each ) { @instance.get_keys_from = :foo  }
           after( :each ) { @instance.get_keys_from = :both }

          it 'causes complaint' do
            expect {
              @instance.get( key: @key )
            }.to raise_error( RuntimeError, "Hoodoo::TransientStore::Base\#get: Invalid prior value given in \#get_keys_from= of ':foo' - only ':both', ':memcached' or ':redis' are allowed" )
          end
        end
      end
    end

    context '#delete' do
      before :each do
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :set ).with( key: @key, payload: @payload, maximum_lifespan: @ttl ).and_call_original()
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :set ).with( key: @key, payload: @payload, maximum_lifespan: @ttl ).and_call_original()

        @instance.set(
          key:              @key,
          payload:          @payload,
          maximum_lifespan: @ttl
        )
      end

      it 'deletes known keys' do
        expect( @instance.get( key: @key ) ).to eql( @payload )

        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :delete ).with( key: @key ).and_call_original()
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :delete ).with( key: @key ).and_call_original()

        result = @instance.delete( key: @key )

        expect( result ).to eq( true )
        expect( @instance.get( key: @key ) ).to eql( nil )
      end

      it 'ignores unknown keys' do
        expect( @instance.delete( key: Hoodoo::UUID.generate() ) ).to eql( true )
      end

      it 'allows Memcached exceptions to propagate but still calls Redis' do
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :delete ).with( key: @key ).and_call_original()
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :delete ) do
          raise "Hello world"
        end

        expect {
          @instance.delete( key: @key )
        }.to raise_error( RuntimeError, "Hello world" )
      end

      it 'allows Redis exceptions to propagate but still calls Memcached' do
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :delete ).with( key: @key ).and_call_original()
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :delete ) do
          raise "Hello world"
        end

        expect {
          @instance.delete( key: @key )
        }.to raise_error( RuntimeError, "Hello world" )
      end
    end

    context '#close' do
      it 'closes normally' do
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :close ).and_call_original()
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :close ).and_call_original()

        @instance.close()
      end

      it 'still closes Redis if Memcached raises an exception' do
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :close ) { raise "Hello world" }
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :close ).and_call_original()

        @instance.close() rescue nil
      end

      it 'still closes Memcached if Redis raises an exception' do
        expect_any_instance_of( Hoodoo::TransientStore::Memcached ).to receive( :close ).and_call_original()
        expect_any_instance_of( Hoodoo::TransientStore::Redis     ).to receive( :close ) { raise "Hello world" }

        @instance.close() rescue nil
      end
    end

  end # 'context "when initialised (#{ backend })" do'

end # 'describe...'
