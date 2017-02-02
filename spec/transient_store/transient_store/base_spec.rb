require 'spec_helper'

describe Hoodoo::TransientStore::Base do
  context 'creation' do
    it 'initialises' do
      base = Hoodoo::TransientStore::Base.new( storage_host_uri: 'localhost' )
      expect( base ).to_not be_nil
      expect( base.instance_variable_get( '@storage_host_uri' ) ).to eq( 'localhost' )
    end
  end

  context 'subclass author warning' do
    before :each do
      @base = Hoodoo::TransientStore::Base.new( storage_host_uri: 'localhost' )
    end

    it 'is generated for #get' do
      expect {
        @base.set( key: 'foo', payload: {}, maximum_lifespan: 5 )
      }.to raise_error( RuntimeError, 'Subclasses must implement Hoodoo::TransientStore::Base#set' )
    end

    it 'is generated for #set' do
      expect {
        @base.get( key: 'foo' )
      }.to raise_error( RuntimeError, 'Subclasses must implement Hoodoo::TransientStore::Base#get' )
    end

    it 'is generated for #delete' do
      expect {
        @base.delete( key: 'foo' )
      }.to raise_error( RuntimeError, 'Subclasses must implement Hoodoo::TransientStore::Base#delete' )
    end

    it 'is generated for #close' do
      expect {
        @base.close()
      }.to raise_error( RuntimeError, 'Subclasses must implement Hoodoo::TransientStore::Base#close' )
    end
  end
end
