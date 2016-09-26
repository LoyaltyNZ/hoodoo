require 'securerandom'
require 'spec_helper.rb'

#
# Create a 'Number' Service with the folloiwng properties:
#
# - manages 'Number' resources ie: { 'number': 3 }, for numbers between 1 & 1000
# - provides a public 'list' endpoint (no session needed)
# - provide many pages of data when asked to 'list' its resource
# - will error if asked for
#
class RSpecNumberImplementation < Hoodoo::Services::Implementation

  public

    # Number resources are all in this range
    NUMBER_RANGE = 0..999

    def list( context )

      resources = []
      0.upto( context.request.list.limit - 1 ) do |i|
        num = context.request.list.offset + i
        resources << { 'number' => num } if NUMBER_RANGE.include?( num )
      end

      # Only error if _all_ the resources asked for are outside the limit
      #errors.add_error( 'synthetic error' ) if NUMBER_RANGE.include?( context.request.list.offset )

      context.response.set_resources( resources, resources.count )
    end

end

#
# Interface for our implementation
#
class RSpecNumberInterface < Hoodoo::Services::Interface
  interface :RSpecNumberTarget do
    endpoint :numbers, RSpecNumberImplementation
    public_actions :list
  end
end

#
# Create an 'Imploder' Service that will error every time its called.
#
class RSpecImploderImplementation < Hoodoo::Services::Implementation

  public

    def list( context )

      errors.add_error( 'Imploded!' )

    end

end

#
# Interface for our implementation
#
class RSpecImploderInterface < Hoodoo::Services::Interface
  interface :RSpecImploderTarget do
    endpoint :explosions, RSpecImploderImplementation
    public_actions :list
  end
end

#############################################################################
#
# Define our service, that implements both resources
#
class RSpecNumberService < Hoodoo::Services::Service
  comprised_of RSpecNumberInterface, RSpecImploderInterface
end


##############################################################################
# Tests
##############################################################################

describe Hoodoo::Client do

  before :all do
    # Start our service in a background thread
    @port = spec_helper_start_svc_app_in_thread_for( RSpecNumberService )
  end

  before :each do
    client = Hoodoo::Client.new({
      drb_port:     URI.parse( Hoodoo::Services::Discovery::ByDRb::DRbServer.uri() ).port,
      auto_session: false
    })
    @number_endpoint   = client.resource( :RSpecNumberTarget, 1)
    @imploder_endpoint = client.resource( :RSpecImploderTarget, 1)
  end

  context 'verify standard "list" behaviour' do

    it 'acts like a resource' do

      results = @number_endpoint.list
      expect( results.platform_errors.has_errors? ).to eq( false )
      expect( results.size                        ).to eq( 50)
      expect( results[0]                          ).to eq( { 'number' => 0 } )
      expect( results[-1]                         ).to eq( { 'number' => 49 } )

    end

    it 'serves up paginated results' do

      0.upto( 3 ) do |page|
        results = @number_endpoint.list( { limit: 250, offset: 250 * page } )
        expect( results.platform_errors.has_errors? ).to eq( false )
        expect( results.size                        ).to eq( 250)
        expect( results[0]                          ).to eq( { 'number' => page * 250 } )
        expect( results[-1]                         ).to eq( { 'number' => (page * 250) + 249 } )
      end

    end

    it 'paginates correctly if we go beyond the last resource' do

      results = @number_endpoint.list( { limit: 100, offset: 950 } )
      expect( results.platform_errors.has_errors? ).to eq( false )
      expect( results.size                        ).to eq( 50 )
      expect( results[0]                          ).to eq( { 'number' => 950 } )
      expect( results[-1]                         ).to eq( { 'number' => 999 } )

    end

    it 'returns an error when forced' do

      results = @imploder_endpoint.list( { limit: 100, offset: 950 } )
      expect( results.platform_errors.has_errors? ).to eq( true )

    end

  end

  context 'verify "list_in_batches" behaviour' do

    it 'errors when the batch_size is invalid' do

      expect { @number_endpoint.list_in_batches( 1.0 ) }.to   raise_error( RuntimeError, 'batch_size must be an Integer' )
      expect { @number_endpoint.list_in_batches( 'abc' ) }.to raise_error( RuntimeError, 'batch_size must be an Integer' )

    end

    it 'takes a block' do

      # Test with different batch sizes
      expected_results = [
        # This first example takes about 20s to run on its own !
        {
          batch_size: 1,
          result_size: 1000.times.collect{ |i| 1 },
        },
        {
          batch_size: 250,
          result_size: [ 250, 250, 250, 250 ],
        },
        {
          batch_size: 500,
          result_size: [ 500, 500 ],
        },
        {
          batch_size: 750,
          result_size: [ 750, 250 ],
        },
        {
          batch_size: 999,
          result_size: [ 999, 1 ],
        },
        {
          batch_size: 1000,
          result_size: [ 1000],
        },
        {
          batch_size: 10001,
          result_size: [ 1000 ],
        },
      ]

      expected_results.each do | expected |
        i = 0
        @number_endpoint.list_in_batches(expected[ :batch_size ]) do | results |
          expect( results.platform_errors.has_errors? ).to eq( false )
          expect( results.size                        ).to eq( expected[ :result_size ][ i ])
          i += 1
        end
        expect( i ).to eq( expected[ :result_size ].size )
      end

    end

  end

end
