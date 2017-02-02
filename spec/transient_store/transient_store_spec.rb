require 'spec_helper'

describe Hoodoo::TransientStore do
  class TestTransientStorePlugin < Hoodoo::TransientStore::Base; end

  context 'registration' do
    it 'allows registration' do
      random_name = Hoodoo::UUID.generate().to_sym()
      Hoodoo::TransientStore.register( as: random_name, using: TestTransientStorePlugin )

      expect( Hoodoo::TransientStore.supported_storage_engines() ).to include( random_name )
    end

    it 'complains about re-registration' do
      random_name = Hoodoo::UUID.generate().to_sym()
      Hoodoo::TransientStore.register( as: random_name, using: TestTransientStorePlugin )

      expect {
        Hoodoo::TransientStore.register( as: random_name, using: TestTransientStorePlugin )
      }.to raise_error( RuntimeError, "Hoodoo::TransientStore.register: A storage engine called '#{ random_name }' is already registered" )
    end

    it 'complains about incorrect subclassing' do
      random_name = Hoodoo::UUID.generate().to_sym()

      expect {
        Hoodoo::TransientStore.register( as: random_name, using: Class )
      }.to raise_error( RuntimeError, "Hoodoo::TransientStore.register requires a Hoodoo::TransientStore::Base subclass - got 'Class'" )
    end

    it 'allows deregistration' do
      random_name = Hoodoo::UUID.generate().to_sym()

      Hoodoo::TransientStore.register( as: random_name, using: TestTransientStorePlugin )
      expect( Hoodoo::TransientStore.supported_storage_engines() ).to include( random_name )

      Hoodoo::TransientStore.deregister( as: random_name )
      expect( Hoodoo::TransientStore.supported_storage_engines() ).to_not include( random_name )
    end
  end
end
