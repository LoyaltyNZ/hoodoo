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

      context.response.set_resources( resources, resources.count )
      context.response.add_error( 'platform.malformed' ) if implode
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
        {
          limit: 10,
        },
        {
          limit: 250,
        },
        {
          limit: 500,
        },
        {
          limit: 750,
        },
        {
          limit: 999,
        },
        {
          limit: 1000,
        },
        {
          limit: 10001,
        },
      ]
    }

    it 'returns every single result with the correct value' do

      next_num = 0
      results = @number_endpoint.list.enumerate_all do | result |

        expect( result.platform_errors.has_errors? ).to eq( false )

        expect( result[ 'number' ] ).to eq( next_num )
        next_num += 1

      end

      # Correct number of results returned
      expect( next_num ).to eq( 1000 )

    end


    it 'takes a block' do

      expected_results.each do | expected |
        i = 0
        results = @number_endpoint.list( { 'limit' => expected[:limit] } ).enumerate_all do | result |
          expect( result.platform_errors.has_errors? ).to eq( false )
          i += 1
        end
        expect( i ).to eq( 1000 )
      end

    end

  end

  context 'error handling behaviour' do

    # Test with different batch sizes
    let(:expected_results) {
      [
        {
          limit: 10,
          errors: 1,
          results: 500,
        },
        {
          limit: 250,
          errors: 1,
          results: 500,
        },
        {
          limit: 499,
          errors: 1,
          results: 499,
        },
        {
          limit: 500,
          errors: 1,
          results: 500,
        },
        {
          limit: 501,
          errors: 1,
          results: 0,
        },
      ]
    }

    it 'returns values until an error occurs in the batch' do

      expected_results.each do | expected |
        #puts expected.inspect
        results = 0
        errors  = 0
        @imploder_endpoint.list( { limit: expected[:limit] } ).enumerate_all do | result |
          results += 1 if result.has_key? 'number'
          errors  += 1 if result.platform_errors.has_errors?
        end
        # Check delivered the correct number of results - note
        # client returns errors or resources, never both
        expect( results ).to eq( expected[ :results ] )
        # Check that an error is returned
        expect( errors ).to eq( expected[ :errors ] )
      end

    end

  end

end
