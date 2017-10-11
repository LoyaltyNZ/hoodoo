require 'spec_helper'

# Most of the mock client is covered by the TransientStore Memcached layer
# tests, which use the mock backend as well as a real one. Tests are implicit.
# This file contains any additional coverage not handled in
# transient_store/transient_store/memcached_spec.rb already.
#
describe Hoodoo::TransientStore::Mocks::DalliClient do

  context 'sanctioned and maintained method' do
    it '::store() returns the data store' do
      Hoodoo::TransientStore::Mocks::DalliClient.reset()
      mock_dalli_client_instance = Hoodoo::TransientStore::Mocks::DalliClient.new
      mock_dalli_client_instance.set( 'foo', 'bar' )
      expect( Hoodoo::TransientStore::Mocks::DalliClient.store ).to have_key( 'foo' )
    end
  end

  # ==========================================================================

  context 'deprecated but indefinitely maintained method' do

    # Chicken and egg - we need to use the methods we're going to test in the
    # test setup to avoid breaking or being broken by prior test execution!

    before :all do
      @old_bypass = Hoodoo::TransientStore::Mocks::DalliClient.bypass?
      Hoodoo::TransientStore::Mocks::DalliClient.bypass( false )
    end

    after :all do
      Hoodoo::TransientStore::Mocks::DalliClient.bypass( @old_bypass )
    end

    it '::bypass=(...) sets and ::bypass?() reads the "bypass" flag' do
      Hoodoo::TransientStore::Mocks::DalliClient.bypass( true )
      expect( Hoodoo::TransientStore::Mocks::DalliClient.bypass? ).to eql( true )

      Hoodoo::TransientStore::Mocks::DalliClient.bypass( false )
      expect( Hoodoo::TransientStore::Mocks::DalliClient.bypass? ).to eql( false )
    end
  end

  context 'approximate old behaviour by' do
    it 'using the mock client in test mode if there is an empty host' do
      expect_any_instance_of( Hoodoo::TransientStore::Mocks::DalliClient ).to receive( :initialize ).once.and_call_original()

      Hoodoo::TransientStore::Memcached.new(
        storage_host_uri: '',
        namespace:        'test_namespace_'
      )
    end

    it 'using the mock client in test mode if there is a "nil" host' do
      expect_any_instance_of( Hoodoo::TransientStore::Mocks::DalliClient ).to receive( :initialize ).once.and_call_original()

      Hoodoo::TransientStore::Memcached.new(
        storage_host_uri: nil,
        namespace:        'test_namespace_'
      )
    end

    it 'using a real client in test mode if there is a defined host' do
      expect_any_instance_of( ::Dalli::Client ).to receive( :initialize ).once.and_call_original()

      # Silence 'Errno::ECONNREFUSED' warnings if Memcached is not actually
      # running at the given URI. That's fine; it's the initializer test
      # above which is important.
      #
      spec_helper_silence_stream( $stdout ) do
        spec_helper_silence_stream( $stderr ) do
          Hoodoo::TransientStore::Memcached.new(
            storage_host_uri: 'localhost:11211',
            namespace:        'test_namespace_'
          )
        end
      end
    end
  end

end
