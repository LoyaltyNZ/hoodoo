require 'spec_helper'

# Most of the mock client is covered by the TransientStore Redis layer tests,
# which use the mock backend as well as a real one. Tests are implicit. This
# file contains any additional coverage not handled in
# transient_store/transient_store/redis_spec.rb already.
#
describe Hoodoo::TransientStore::Mocks::Redis do

  context 'sanctioned and maintained method' do
    it '::store() returns the data store' do
      Hoodoo::TransientStore::Mocks::Redis.reset()
      mock_redis_instance = Hoodoo::TransientStore::Mocks::Redis.new
      mock_redis_instance.set( 'foo', 'bar' )
      expect( Hoodoo::TransientStore::Mocks::Redis.store ).to have_key( 'foo' )
    end

    it '#expire(...) raises an error for attempts to expire bad keys' do
      mock_redis_instance = Hoodoo::TransientStore::Mocks::Redis.new
      key                 = Hoodoo::UUID.generate()

      expect {
        mock_redis_instance.expire( key, 60 )
      }.to raise_error( RuntimeError, "Hoodoo::TransientStore::Mocks::Redis\#expire: Cannot find key '#{ key }'" )
    end
  end

  context 'mimic approcimated old behaviour of its Memcached counterpart by' do
    it 'using the mock client in test mode if there is an empty host' do
      expect_any_instance_of( Hoodoo::TransientStore::Mocks::Redis ).to receive( :initialize ).once.and_call_original()

      Hoodoo::TransientStore::Redis.new(
        storage_host_uri: '',
        namespace:        'test_namespace_'
      )
    end

    it 'using the mock client in test mode if there is a "nil" host' do
      expect_any_instance_of( Hoodoo::TransientStore::Mocks::Redis ).to receive( :initialize ).once.and_call_original()

      Hoodoo::TransientStore::Redis.new(
        storage_host_uri: nil,
        namespace:        'test_namespace_'
      )
    end

    it 'using a real client in test mode if there is a defined host' do
      expect_any_instance_of( ::Redis ).to receive( :initialize ).once.and_call_original()

      # Silence 'Errno::ECONNREFUSED' warnings if Memcached is not actually
      # running at the given URI. That's fine; it's the initializer test
      # above which is important.
      #
      spec_helper_silence_stream( $stdout ) do
        spec_helper_silence_stream( $stderr ) do
          Hoodoo::TransientStore::Redis.new(
            storage_host_uri: 'redis://localhost:6379',
            namespace:        'test_namespace_'
          )
        end
      end
    end
  end

end
