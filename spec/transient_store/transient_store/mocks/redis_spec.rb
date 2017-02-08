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

end
