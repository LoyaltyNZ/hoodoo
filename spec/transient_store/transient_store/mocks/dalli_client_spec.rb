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

end
