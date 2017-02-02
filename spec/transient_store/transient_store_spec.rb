require 'spec_helper'

# These tests assume the Memcached plugin is available and has been unit
# tested thoroughly elsewhere.
#
describe Hoodoo::TransientStore do
  class TestTransientStore < Hoodoo::TransientStore::Base
  end

  context 'registration' do
    it 'allows registration' do
      random_name = Hoodoo::UUID.generate().to_sym()
      Hoodoo::TransientStore.register( as: random_name, using: TestTransientStore )

      expect( Hoodoo::TransientStore.supported_storage_engines() ).to include( random_name )
    end

    it 'complains about re-registration' do
      random_name = Hoodoo::UUID.generate().to_sym()
      Hoodoo::TransientStore.register( as: random_name, using: TestTransientStore )

      expect {
        Hoodoo::TransientStore.register( as: random_name, using: TestTransientStore )
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

      Hoodoo::TransientStore.register( as: random_name, using: TestTransientStore )
      expect( Hoodoo::TransientStore.supported_storage_engines() ).to include( random_name )

      Hoodoo::TransientStore.deregister( as: random_name )
      expect( Hoodoo::TransientStore.supported_storage_engines() ).to_not include( random_name )
    end
  end

  context '#initialize' do
    before :all do
      Hoodoo::TransientStore.class_variable_set( '@@supported_storage_engines', {} ) # Hack for test!

      @engine_name = Hoodoo::UUID.generate().to_sym
      Hoodoo::TransientStore.register( as: @engine_name, using: TestTransientStore )
    end

    it 'initialises' do
      max_life = 120
      uri      = 'localhost'

      expect( TestTransientStore ).to receive( :new ).with( storage_host_uri: uri )

      result = Hoodoo::TransientStore.new(
        storage_engine:           @engine_name,
        storage_host_uri:         uri,
        default_maximum_lifespan: max_life
      )

      expect( result ).to be_a( Hoodoo::TransientStore )
      expect( result.storage_engine ).to eql( @engine_name )
      expect( result.default_maximum_lifespan ).to eql( max_life )
    end

    it 'initialises with defaults' do
      result = Hoodoo::TransientStore.new(
        storage_engine:   @engine_name,
        storage_host_uri: 'localhost'
      )

      expect( result.default_maximum_lifespan ).to eql( 604800 ) # Per RDoc description of default
    end

    it 'complains about unknown storage engines' do
      # Add a couple more know engine names
      #
      Hoodoo::TransientStore.register( as: 'foo', using: TestTransientStore )
      Hoodoo::TransientStore.register( as: 'bar', using: TestTransientStore )

      expect {
        result = Hoodoo::TransientStore.new(
          storage_engine:   :baz,
          storage_host_uri: 'localhost'
        )
      }.to raise_error( RuntimeError, "Hoodoo::TransientStore: Unrecognised storage engine ':baz' requested; allowed values: '#{ @engine_name.to_sym.inspect }', ':foo', ':bar'" )
    end
  end
end
