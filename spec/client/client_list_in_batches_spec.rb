require 'securerandom'
require 'spec_helper.rb'

#
# Create a 'Number' Service with the following properties:
#
# - manages 'Number' resources ie: { 'number': 3 }, for numbers between 0 & 999
# - provides a public 'list' endpoint (no session needed)
# - pagination
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
# Create a 'Imploder' Service with the following properties:
#
# - manages 'Number' resources ie: { 'number': 3 }, for numbers between 0 & 999
# - provides a public 'list' endpoint (no session needed)
# - pagination
# - will generate an error when asked to retrieve any 'Number' resource with a
#   number value >= 500
#
#
class RSpecImploderImplementation < Hoodoo::Services::Implementation

  public

    # Number resources are all in this range
    NUMBER_RANGE = 0..999

    # Number resources that generate errors are all in this range
    ERROR_RANGE  = 500..999

    def list( context )

      resources = []
      implode = false
      0.upto( context.request.list.limit - 1 ) do |i|
        num = context.request.list.offset + i
        resources << { 'number' => num } if NUMBER_RANGE.include?( num )
        implode = implode || ERROR_RANGE.include?( num )
      end

      context.response.add_error( 'platform.malformed' ) if implode
      return if context.response.halt_processing?

      context.response.set_resources( resources, resources.count )
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

  context 'verify the test service endpoints implement standard "list" behaviour' do

    context 'RSpecNumber' do

      it 'acts like a resource' do

        results = @number_endpoint.list
        expect( results.platform_errors.has_errors? ).to eq( false )
        expect( results.size                        ).to eq( 50)
        expect( results[0]                          ).to eq( { 'number' => 0 } )
        expect( results[-1]                         ).to eq( { 'number' => 49 } )

      end

      it 'serves up paginated results' do

        0.upto( 3 ) do | page |
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

      it 'paginates correctly if we go beyond the last resource' do

        results = @number_endpoint.list( { limit: 100, offset: 950 } )
        expect( results.platform_errors.has_errors? ).to eq( false )
        expect( results.size                        ).to eq( 50 )
        expect( results[0]                          ).to eq( { 'number' => 950 } )
        expect( results[-1]                         ).to eq( { 'number' => 999 } )

      end

    end

    context 'RSpecImploder' do

      it 'acts like a resource' do

        results = @imploder_endpoint.list
        expect( results.platform_errors.has_errors? ).to eq( false )
        expect( results.size                        ).to eq( 50 )
        expect( results[0]                          ).to eq( { 'number' => 0 } )
        expect( results[-1]                         ).to eq( { 'number' => 49 } )

      end

      it 'generates errors, when asked for numbers >= 500' do

        0.upto( 3 ) do | page |
          results = @imploder_endpoint.list( { limit: 250, offset: 250 * page } )
          if page < 2
            expect( results.platform_errors.has_errors? ).to eq( false )
            expect( results.size                        ).to eq( 250 )
            expect( results[0]                          ).to eq( { 'number' => page * 250 } )
            expect( results[-1]                         ).to eq( { 'number' => (page * 250) + 249 } )
          else
            expect( results.platform_errors.has_errors? ).to eq( true )
            expect( results.size                        ).to eq( 0 )
          end
        end

      end

    end

  end

  context 'happy path behaviour' do

    # Test with different batch sizes
    let(:expected_results) {
      [
        # If the batch_size is 1, this example takes about 20s to run on its own !
        # Batches of size 10 seems like a reasonable compromise of small batch size
        # and fast execution
        {
          batch_size: 10,
          result_size: 100.times.collect{ |i| 10 },
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
    }

    it 'errors when the batch_size is invalid' do

      expect { @number_endpoint.list_in_batches( 1.0 ) }.to   raise_error( RuntimeError, 'batch_size must be an Integer' )
      expect { @number_endpoint.list_in_batches( 'abc' ) }.to raise_error( RuntimeError, 'batch_size must be an Integer' )

    end

    it 'returns every single result with the correct value' do

      next_num = 0
      @number_endpoint.list_in_batches(250) do | results |

        expect( results.platform_errors.has_errors? ).to eq( false )

        # Check each result in the batch
        results.each do | result |
          expect( result[ 'number' ] ).to eq( next_num )
          next_num += 1
        end

      end

      # Correct number of results returned
      expect( next_num ).to eq( 1000 )

    end


    it 'takes a block' do

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

    it 'returns an Enumerator object' do

      expect( @number_endpoint.list_in_batches( 500 ) ).to be_a_kind_of( Enumerator )

    end

    it 'allows for enumeration' do

      expected_results.each do | expected |
        i = 0
        @number_endpoint.list_in_batches(expected[ :batch_size ]).with_index do | results, idx |
          expect( results.platform_errors.has_errors? ).to eq( false )
          expect( results.size                        ).to eq( expected[ :result_size ][ i ])
          expect( idx                                 ).to eq( i )
          i += 1
        end
        expect( i ).to eq( expected[ :result_size ].size )
      end

    end

  end

  context 'error handling behaviour' do

    # Test with different batch sizes
    let(:expected_results) {
      [
        {
          batch_size: 10,
          result_size: 50.times.collect{ |i| 10 },
        },
        {
          batch_size: 250,
          result_size: [ 250, 250 ],
        },
        {
          batch_size: 499,
          result_size: [ 499 ],
        },
        {
          batch_size: 500,
          result_size: [ 500 ],
        },
        {
          batch_size: 501,
          result_size: [  ],
        },
      ]
    }

    it 'returns batches until an error occurs' do

      expected_results.each do | expected |
        i = 0
        imploded = false
        @imploder_endpoint.list_in_batches( expected[ :batch_size ] ) do | results |
          if results.platform_errors.has_errors?
            # No more batches should be delivered once an error occurs
            expect( imploded ).to eq( false )
            imploded = true
          else
            expect( results.size ).to eq( expected[ :result_size ][ i ])
            i += 1
          end
        end
        # Check delivered the correct number of batches
        expect( i ).to eq( expected[ :result_size ].size )
        # Check that an error is returned
        expect( imploded ).to eq( true )
      end

    end

  end

end
