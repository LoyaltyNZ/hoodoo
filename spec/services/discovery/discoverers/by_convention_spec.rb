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
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/3/Apple')

      result = @d.announce( 'Sheep', 2 )
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/2/Sheep')
    end

    it 'discovers' do
      @d.announce( 'Apple', 3 )
      @d.instance_variable_set( '@known_local_resources', {} ) # Hack for test!

      result = @d.discover( :Apple, 3 )
      expect( result ).to be_a( Hoodoo::Services::Discovery::ForHTTP )
      expect( result.resource ).to eq( :Apple )
      expect( result.version ).to eq( 3 )
      expect( result.endpoint_uri.to_s ).to eq( 'http://pond.org.uk/3/Apple')
    end
  end
end
