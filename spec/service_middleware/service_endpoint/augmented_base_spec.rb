require 'spec_helper'

describe ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedBase do

  class AugmentedBaseTest
    include ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedBase
  end

  before :each do
    @abt = AugmentedBaseTest.new
    @fof = ApiTools::Errors.new
    @fof.add_error( 'platform.timeout' )
  end

  context 'without externally set collection' do
    it 'generates its own collection' do
      e = @abt.platform_errors
      expect( e ).to be_a( ApiTools::Errors )
      expect( e.has_errors? ).to eq( false )
    end

    it 'merges properly' do
      # There are no errors inside @abt to add to @fof, so should return 'false'
      expect( @abt.adds_errors_to?( @fof ) ).to eq( false )
      data = @fof.render()
      expect( data[ 'errors' ] ).to be_a( Array )
      expect( data[ 'errors' ].size ).to eq( 1 )
      expect( data[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.timeout' )
    end
  end

  context 'with externally set collection' do

    it 'sets and returns errors collections' do
      @abt.set_platform_errors( @fof )
      expect( @abt.platform_errors ).to eq( @fof )
      expect( @abt.platform_errors.has_errors? ).to eq( true )
    end

    it 'merges properly' do
      col = ApiTools::Errors.new
      @abt.set_platform_errors( @fof )
      expect( @abt.adds_errors_to?( col ) ).to eq( true )
      data = col.render()
      expect( data[ 'errors' ] ).to be_a( Array )
      expect( data[ 'errors' ].size ).to eq( 1 )
      expect( data[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.timeout' )
    end
  end
end
