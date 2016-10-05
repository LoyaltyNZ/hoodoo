require 'securerandom'
require 'spec_helper.rb'

#
# These tests define the following Services.
#
# Clients can call into any of them to invoke the different calling semantics
# between them.
#
#
# ┌──────────────────────────────────────────────┐ ┌──────────────────────────┐
# │                                              │ │                          │
# │               RSpecNumberService             │ │ RSpecRemoteNumberService │
# │                                              │ │                          │
# │                                              │ │                          │
# │ ┌──────────────┐           ┌────────────────┐│ │  ┌───────────────────┐   │
# │ │              │  inter    │                ││ │  │                   │   │
# │ │ RSpecNumber  │◀resource ─│RSpecEvenNumber ││ │  │  RSpecOddNumber   │   │
# │ │              │  local    │                ││ │  │                   │   │
# │ └──────────────┘           └────────────────┘│ │  └───────────────────┘   │
# │         ▲                                    │ │            │             │
# │         │                            inter   │ │            │             │
# │         └───────────────────────────resource ┼─┼────────────┘             │
# │                                      remote  │ │                          │
# └──────────────────────────────────────────────┘ └──────────────────────────┘
#
# To start the services in your specs do:
#
#     spec_helper_start_svc_app_in_thread_for( RSpecNumberService )
#     spec_helper_start_svc_app_in_thread_for( RSpecRemoteNumberService)
#

################################################################################
#
# Create a 'RSpecNumber' Resource with the following properties:
#
# - manages 'Number' resources ie: { 'number': 3 }, for numbers between 0 & 999
# - provides a public 'list' endpoint (no session needed)
# - pagination
# - will generate an error when asked to retrieve any 'Number' resource with a
#   number value >= 500 && filter_data['force_error'] is set (to anything)
#
class RSpecNumberImplementation < Hoodoo::Services::Implementation

  public

  # Number resources are all in this range
  NUMBER_RANGE = 0..999

  # Number resources that generate errors are all in this range
  ERROR_RANGE  = 500..999

  def list( context )
    request  = context.request

    resources = []
    implode = false
    0.upto( request.list.limit - 1 ) do |i|
      num = request.list.offset + i
      implode = implode || ERROR_RANGE.include?( num )
      if NUMBER_RANGE.include?( num )
        resources << { 'number' => num }
      else
        break
      end
    end

    context.response.set_resources( resources, resources.count )
    if implode && request.list.filter_data[ 'force_error' ]
      context.response.add_error( 'platform.malformed' )
    end
  end

end

#
# Interface for our implementation
#
class RSpecNumberInterface < Hoodoo::Services::Interface
  interface :RSpecNumber do
    endpoint       :numbers, RSpecNumberImplementation
    to_list do
      filter :force_error
    end
    public_actions :list
  end
end


################################################################################
#
# Create a 'RSpecEvenNumber' Resource with the following properties:
#
# - Calls RSpecNumber via the 'inter_resource_local' calling mechanism
# - Only returns 'even' numbers, 0, 2, 4... for numbers between 0 & 999
# - provides a public 'list' endpoint (no session needed)
#
# See RSpecNumberImplementation for error handling etc
#
class RSpecEvenNumberImplementation < Hoodoo::Services::Implementation

  public

  def list( context )
    request   = context.request
    endpoint  = context.resource( :RSpecNumber, 1 )
    resources = []
    limit     = request.list.limit  ? request.list.limit  : 50
    offset    = request.list.offset ? request.list.offset : 0

    # We always iterate through every Number resource - yeah its dumb
    endpoint.list( { :filter => request.list.filter_data } ).enumerate_all do | number_res |

      if number_res.platform_errors.has_errors?
        context.response.add_errors( number_res.platform_errors )
        break
      end

      number = number_res['number']

      # Number in the correct range & is 'even'
      resources << number_res if number >= ( offset * 2 ) && number.even?
      break if resources.size >= limit

    end

    context.response.set_resources( resources, resources.count )
  end

end

#
# Interface for our implementation
#
class RSpecEvenNumberInterface < Hoodoo::Services::Interface
  interface :RSpecEvenNumber do
    endpoint       :even_numbers, RSpecEvenNumberImplementation
    to_list do
      filter :force_error
    end
    public_actions :list
  end
end

################################################################################
#
# Define our service, that implements both resources
#
class RSpecNumberService < Hoodoo::Services::Service
  comprised_of RSpecNumberInterface,
               RSpecEvenNumberInterface
end


################################################################################
#
# Create a 'RSpecOddNumber' Resource with the following properties:
#
# - Calls RSpecNumber via the 'inter_resource_remote' calling mechanism
# - Only returns 'odd' numbers, 1, 3, 5 ... for numbers between 0 & 999
# - provides a public 'list' endpoint (no session needed)
#
# See RSpecNumberImplementation for error handling etc
#
class RSpecOddNumberImplementation < Hoodoo::Services::Implementation

  public

  def list( context )
    request   = context.request
    endpoint  = context.resource( :RSpecNumber, 1 )
    resources = []
    limit     = request.list.limit  ? request.list.limit  : 50
    offset    = request.list.offset ? request.list.offset : 0

    # We always iterate through every Number resource - yeah its dumb
    endpoint.list( { :filter => request.list.filter_data } ).enumerate_all do | number_res |

      if number_res.platform_errors.has_errors?
        context.response.add_errors( number_res.platform_errors )
        break
      end

      number = number_res['number']

      # Number in the correct range & is 'odd'
      resources << number_res if number >= ( offset * 2 ) && number.odd?
      break if resources.size >= limit

    end

    context.response.set_resources( resources, resources.count )
  end

end

#
# Interface for our implementation
#
class RSpecOddNumberInterface < Hoodoo::Services::Interface
  interface :RSpecOddNumber do
    endpoint       :odd_numbers, RSpecOddNumberImplementation
    to_list do
      filter :force_error
    end
    public_actions :list
  end
end

################################################################################
#
# Define our service, that implements both resources
#
class RSpecRemoteNumberService < Hoodoo::Services::Service
  comprised_of RSpecOddNumberInterface
end



##############################################################################
# Tests
##############################################################################

describe Hoodoo::Client do

  before :all do

    # Start our services in background threads
    spec_helper_start_svc_app_in_thread_for( RSpecNumberService )
    spec_helper_start_svc_app_in_thread_for( RSpecRemoteNumberService )

  end

  before :each do

    @client = Hoodoo::Client.new({
      drb_port:     URI.parse( Hoodoo::Services::Discovery::ByDRb::DRbServer.uri() ).port,
      auto_session: false
    })

  end

  context 'happy path behaviour' do

    let( :resources ) { [
      {
        endpoint:     @client.resource( :RSpecNumber, 1 ),
        data:         (0..999).to_a
      },
      {
        endpoint:     @client.resource( :RSpecEvenNumber, 1 ),
        data:         (0..999).step(2).to_a
      },
      {
        endpoint:     @client.resource( :RSpecOddNumber, 1 ),
        data:         (1..999).step(2).to_a
      },
    ] }

    it 'returns every single result with the correct value' do

      resources.each do | resource |
        numbers = []

        resource[ :endpoint ].list.enumerate_all do | result |
          expect( result.platform_errors.errors ).to eq( [] )
          break if result.platform_errors.has_errors?
          numbers << result[ 'number' ]
        end

        expect( numbers ).to eq( resource[ :data ] )
      end

    end

    context 'different "limit" sizes' do

      let(:limits) {
        # Note: Smaller limits will make the tests very slow
        [ 250, 500, 750, 999, 1000, 1001 ]
      }

      it 'enumerates correctly with different batch sizes' do

        resources.each do | resource |
          limits.each do | limit |
            numbers = []

            resource[ :endpoint ].list( { 'limit' => limit } ).enumerate_all do | result |
              expect( result.platform_errors.errors ).to eq( [] )
              break if result.platform_errors.has_errors?
              numbers << result[ 'number' ]
            end

            expect( numbers ).to eq( resource[ :data ] )
          end
        end

      end

    end

  end

  context 'error handling behaviour' do

    let( :resources ) { [
      {
        endpoint:         @client.resource( :RSpecNumber, 1 ),
        expected_results: [
                            {
                              limit:  10,
                              data:   ( 0..499 ).to_a,
                            },
                            {
                              limit:  250,
                              data:   ( 0..499 ).to_a,
                            },
                            {
                              limit:  499,
                              data:   ( 0..498 ).to_a,
                            },
                            {
                              limit:  500,
                              data:   ( 0..499 ).to_a,
                            },
                            {
                              limit:  501,
                              data:   [],
                            },
                          ]
      },
      {
        endpoint:         @client.resource( :RSpecEvenNumber, 1 ),
        expected_results: [
                            {
                              limit:  10,
                              data:   ( 0..498 ).step(2).to_a
                            },
                            {
                              limit:  249,
                              data:   ( 0..496 ).step(2).to_a
                            },
                            {
                              limit:  250,
                              data:   ( 0..498 ).step(2).to_a
                            },
                            {
                              limit:  251,
                              data:   []
                            },
                          ]
      },
      {
        endpoint:         @client.resource( :RSpecOddNumber, 1 ),
        expected_results: [
                            {
                              limit:  10,
                              data:   ( 1..499 ).step(2).to_a
                            },
                            {
                              limit:  249,
                              data:   ( 1..497 ).step(2).to_a
                            },
                            {
                              limit:  250,
                              data:   ( 1..499 ).step(2).to_a
                            },
                            {
                              limit:  251,
                              data:   []
                            },
                          ]
      },
    ] }

    it 'returns values until an error occurs in the "list" call' do

      resources.each do | resource |
        resource[ :expected_results ].each do | expected |

          numbers    = []
          errors     = 0
          query_hash = {
            'limit'   => expected[ :limit ],
            'filter'  => {
              'force_error' => 'true'
            }
          }

          resource[ :endpoint ].list( query_hash ).enumerate_all do | result |
            numbers << result[ 'number' ] if result.has_key? 'number'
            errors  += 1 if result.platform_errors.has_errors?
          end

          # The number of valid resources that you recieve is dependent on
          # the 'limit' size that is passed through on the 'list' call
          #
          # Thats because the system will enumerate through an entire batch of
          # resources (of size limit), OR return an error.
          #
          # So the underlying service retrieves 50 valid resources and returns
          # then the caller will enumerate through those 50. On the other hand if
          # the service reads 50 resources, and then detects an error on the 51st
          # then 0 resources are retuned, only an error!
          #
          expect( numbers ).to eq( expected[ :data ] )
          # Check that an error is returned
          expect( errors ).to eq( 1 )
        end
      end

    end


    it 'raises an exception if no block supplied' do

      endpoints = [
          @client.resource( :RSpecNumber, 1 ),
          @client.resource( :RSpecEvenNumber, 1 ),
          @client.resource( :RSpecOddNumber, 1 ),
      ]

      endpoints.each do | endpoint |
        expect {
          endpoint.list.enumerate_all
        }.to raise_exception( RuntimeError, 'Must provide a block to enumerate_all' )
      end

    end

  end

end
