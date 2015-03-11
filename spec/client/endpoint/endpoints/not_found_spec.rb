require 'spec_helper'

describe Hoodoo::Client::Endpoint::NotFound do
  before :each do
    @endpoint = described_class.new( :NotFoundResource, 1, {} )
  end

  context 'produces "not found" result for' do
    def run_expectations( result )
      expect( result.platform_errors ).to_not be_nil
      expect( result.platform_errors.errors.size ).to eq( 1 )
      expect( result.platform_errors.errors[ 0 ][ 'code' ] ).to eq( 'platform.not_found' )
    end

    it '#list' do
      run_expectations( @endpoint.list() )
    end

    it '#show' do
      run_expectations( @endpoint.show( 'foo' ) )
    end

    it '#create' do
      run_expectations( @endpoint.create( {} ) )
    end

    it '#update' do
      run_expectations( @endpoint.update( 'foo', {} ) )
    end

    it '#delete' do
      run_expectations( @endpoint.delete( 'foo' ) )
    end
  end
end
