require 'spec_helper'

# These tests assume the Memcached plugin is available and has been unit
# tested thoroughly elsewhere.
#
describe Hoodoo::TransientStore do

  RDOC_STATED_DEFAULT_LIFESPAN = 604800

  class TestTransientStore < Hoodoo::TransientStore::Base
    def initialize( storage_host_uri: )
      @store = {}
    end

    def set( key:, payload:, maximum_lifespan: )
      @store[ key ] = payload
      true
    end

    def get( key: )
      @store[ key ]
    end

    def delete( key: )
      @store.delete( key )
      true
    end
  end

  # ==========================================================================

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

  # ==========================================================================

  context 'with' do

    before :each do
      @engine_name = Hoodoo::UUID.generate().to_sym
      Hoodoo::TransientStore.register( as: @engine_name, using: TestTransientStore )
    end

    context '#initialize' do
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

        expect( result.default_maximum_lifespan ).to eql( RDOC_STATED_DEFAULT_LIFESPAN )
      end

      context 'unknown storage engines' do
        before :each do
          @old_engines = Hoodoo::TransientStore.class_variable_get( '@@supported_storage_engines' )
          Hoodoo::TransientStore.class_variable_set( '@@supported_storage_engines', { @engine_name => TestTransientStore } ) # Hack for test!
        end

        after :each do
          Hoodoo::TransientStore.class_variable_set( '@@supported_storage_engines', @old_engines ) # Hack for test!
        end

        it 'cause complaint' do
          # Add two more engine names
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

    # ========================================================================

    context '#set' do
      before :each do
        @instance = Hoodoo::TransientStore.new(
          storage_engine:   @engine_name,
          storage_host_uri: 'localhost'
        )
      end

      it 'sets with default lifespan' do
        key     = Hoodoo::UUID.generate()
        payload = { 'foo' => 'bar' }

        expect_any_instance_of( TestTransientStore ).to(
          receive( :set ).
          with(
            key:              key,
            payload:          payload,
            maximum_lifespan: RDOC_STATED_DEFAULT_LIFESPAN
          ).
          and_call_original()
        )

        result = @instance.set( key: key, payload: payload )
        expect( result ).to eq( true )
      end

      it 'sets with explicit lifespan' do
        key      = Hoodoo::UUID.generate()
        payload  = { 'foo' => 'bar' }
        lifespan = 1

        expect_any_instance_of( TestTransientStore ).to(
          receive( :set ).
          with(
            key:              key,
            payload:          payload,
            maximum_lifespan: lifespan
          ).
          and_call_original()
        )

        result = @instance.set( key: key, payload: payload, maximum_lifespan: lifespan )
        expect( result ).to eq( true )
      end

      it 'consumes and returns exceptions' do
        expect_any_instance_of( TestTransientStore ).to receive( :set ) do
          raise 'Hello world'
        end

        result = @instance.set( key: '1', payload: '2' )

        expect( result ).to be_a( RuntimeError )
        expect( result.message ).to eql( 'Hello world' )
      end

      it 'prohibits "nil" payloads' do
        expect {
          result = @instance.set( key: '1', payload: nil )
        }.to raise_error( RuntimeError, "Hoodoo::TransientStore\#set: Payloads of 'nil' are prohibited" )
      end

      it 'detects faulty engines' do
        expect_any_instance_of( TestTransientStore ).to receive( :set ) do
          'not a boolean'
        end

        result = @instance.set( key: '1', payload: '2' )

        expect( result ).to be_a( RuntimeError )
        expect( result.message ).to eql( "Hoodoo::TransientStore\#set: Engine '#{ @engine_name }' returned an invalid response" )
      end

      context 'key normalisation' do
        it 'normalises the key' do
          key = :some_symbol

          expect_any_instance_of( TestTransientStore ).to(
            receive( :set ).with(
              key:              key.to_s, # i.e. Symbol has been normalised to String
              payload:          {},
              maximum_lifespan: RDOC_STATED_DEFAULT_LIFESPAN
            )
          )

          @instance.set( key: key, payload: {} )
        end

        it 'complains about unsupported key types' do
          expect {
            @instance.set( key: Hash.new, payload: {} )
          }.to raise_error( RuntimeError, "Hoodoo::TransientStore\#set: Keys must be of String or Symbol class; you provided 'Hash'" )
        end

        it 'complains about empty keys' do
          expect {
            @instance.set( key: '', payload: {} )
          }.to raise_error( RuntimeError, 'Hoodoo::TransientStore#set: Empty String or Symbol keys are prohibited' )
        end
      end
    end

    # ========================================================================

    context '#get' do
      before :each do
        @instance = Hoodoo::TransientStore.new(
          storage_engine:   @engine_name,
          storage_host_uri: 'localhost'
        )

        @key     = Hoodoo::UUID.generate()
        @payload = { 'foo' => 'bar' }

        @instance.set( key: @key, payload: @payload )
      end

      it 'gets known keys' do
        expect_any_instance_of( TestTransientStore ).to(
          receive( :get ).with( key: @key ).and_call_original()
        )

        expect( @instance.get( key: @key ) ).to eql( @payload )
      end

      it 'returns "nil" for unknown keys' do
        random_key = Hoodoo::UUID.generate()

        expect_any_instance_of( TestTransientStore ).to(
          receive( :get ).with( key: random_key ).and_call_original()
        )

        expect( @instance.get( key: random_key ) ).to be_nil
      end

      it 'consumes exceptions' do
        expect_any_instance_of( TestTransientStore ).to receive( :get ) do
          raise 'Hello world'
        end

        expect( @instance.get( key: @key ) ).to be_nil
      end

      context 'key normalisation' do
        it 'normalises the key' do
          key = :some_symbol

          expect_any_instance_of( TestTransientStore ).to(
            receive( :get ).with(
              key: key.to_s # i.e. Symbol has been normalised to String
            )
          )

          @instance.get( key: key )
        end

        it 'complains about unsupported key types' do
          expect {
            @instance.get( key: Hash.new )
          }.to raise_error( RuntimeError, "Hoodoo::TransientStore\#get: Keys must be of String or Symbol class; you provided 'Hash'" )
        end

        it 'complains about empty keys' do
          expect {
            @instance.get( key: '' )
          }.to raise_error( RuntimeError, 'Hoodoo::TransientStore#get: Empty String or Symbol keys are prohibited' )
        end
      end
    end

    # ========================================================================

    context '#delete' do
      before :each do
        @instance = Hoodoo::TransientStore.new(
          storage_engine:   @engine_name,
          storage_host_uri: 'localhost'
        )

        @key     = Hoodoo::UUID.generate()
        @payload = { 'foo' => 'bar' }

        @instance.set( key: @key, payload: @payload )
      end

      it 'deletes known keys' do
        expect( @instance.get( key: @key ) ).to eql( @payload )

        expect_any_instance_of( TestTransientStore ).to(
          receive( :delete ).with( key: @key ).and_call_original()
        )

        expect( @instance.delete( key: @key ) ).to eql( true )
        expect( @instance.get( key: @key ) ).to be_nil
      end

      it 'ignores unknown keys' do
        random_key = Hoodoo::UUID.generate()

        expect_any_instance_of( TestTransientStore ).to(
          receive( :delete ).with( key: random_key ).and_call_original()
        )

        expect( @instance.delete( key: random_key ) ).to eql( true )
      end

      it 'consumes and returns exceptions' do
        expect_any_instance_of( TestTransientStore ).to receive( :delete ) do
          raise 'Hello world'
        end

        result = @instance.delete( key: @key )

        expect( result ).to be_a( RuntimeError )
        expect( result.message ).to eql( 'Hello world' )
      end

      it 'detects faulty engines' do
        expect_any_instance_of( TestTransientStore ).to receive( :delete ) do
          'not a boolean'
        end

        result = @instance.delete( key: @key )

        expect( result ).to be_a( RuntimeError )
        expect( result.message ).to eql( "Hoodoo::TransientStore\#delete: Engine '#{ @engine_name }' returned an invalid response" )
      end

      context 'key normalisation' do
        it 'normalises the key' do
          key = :some_symbol

          expect_any_instance_of( TestTransientStore ).to(
            receive( :delete ).with(
              key: key.to_s # i.e. Symbol has been normalised to String
            )
          )

          @instance.delete( key: key )
        end

        it 'complains about unsupported key types' do
          expect {
            @instance.delete( key: Hash.new )
          }.to raise_error( RuntimeError, "Hoodoo::TransientStore\#delete: Keys must be of String or Symbol class; you provided 'Hash'" )
        end

        it 'complains about empty keys' do
          expect {
            @instance.delete( key: '' )
          }.to raise_error( RuntimeError, 'Hoodoo::TransientStore#delete: Empty String or Symbol keys are prohibited' )
        end
      end
    end

  end
end
