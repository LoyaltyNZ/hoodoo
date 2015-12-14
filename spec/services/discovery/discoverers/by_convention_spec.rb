require 'spec_helper'

describe Hoodoo::Services::Discovery::ByConvention do
  context 'with default routing' do
    before :each do
      @d = described_class.new( :base_uri => 'http://pond.org.uk' )
    end

    it 'announces' do
      result = @d.announce( 'Apple', '3' ) # Intentional string use
      expect( result ).to be_a( Hoodoo::Services::Discovery::ForHTTP )
      expect( result.resource ).to eq( :Apple )
      expect( result.version ).to eq( 3 )
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/v3/apples')

      result = @d.announce( 'Sheep', 2 )
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/v2/sheep')
    end

    it 'discovers' do
      @d.announce( 'Apple', 3 )
      @d.instance_variable_set( '@known_local_resources', {} ) # Hack for test!

      result = @d.discover( :Apple, 3 )
      expect( result ).to be_a( Hoodoo::Services::Discovery::ForHTTP )
      expect( result.resource ).to eq( :Apple )
      expect( result.version ).to eq( 3 )
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/v3/apples')
    end
  end

  context 'with overridden routing' do
    before :each do
      @d = described_class.new(
        :base_uri => 'http://pond.org.uk',
        :routing => {
          :Version => { 1 => '/v1/version', 2 => '/version_2/version_singleton' },
          :Health  => { 2 => '/v2/health' }
        }
      )
    end

    it 'discovers' do
      @d.announce( :Version, 1 )
      @d.announce( 'Version', 2 ) # Intentional string use
      @d.announce( :Version, 3 )
      @d.announce( :Apple, 3 )
      @d.announce( :Health, 1 )
      @d.announce( :Health, 2 )

      @d.instance_variable_set( '@known_local_resources', {} ) # Hack for test!

      result = @d.discover( :Version, 1 )
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/v1/version')
      result = @d.discover( :Version, 2 )
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/version_2/version_singleton')
      result = @d.discover( :Version, 3 )
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/v3/versions')
      result = @d.discover( :Apple, 3 )
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/v3/apples')
      result = @d.discover( :Health, 1 )
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/v1/healths')
      result = @d.discover( :Health, 2 )
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/v2/health')
    end
  end
end
