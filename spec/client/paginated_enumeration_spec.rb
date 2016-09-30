require 'securerandom'
require 'spec_helper.rb'



##############################################################################
# Tests
##############################################################################

describe Hoodoo::Client do

  before :all do

    # Start our services in background threads
    spec_helper_start_svc_app_in_thread_for( RSpecNumberService )
    spec_helper_start_svc_app_in_thread_for( RSpecRemoteNumberService)

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
        endpoint:     @client.resource( :RSpecNumber, 1),
        data:         (0..999).to_a
      },
      {
        endpoint:     @client.resource( :RSpecEvenNumber, 1),
        data:         (0..999).step(2).to_a
      },
      {
        endpoint:     @client.resource( :RSpecOddNumber, 1),
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
        # Note: Smaller limits will make the tests very slooooow
        [ 25, 250, 500, 750, 999, 1000, 1001 ]
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
        endpoint:         @client.resource( :RSpecNumber, 1),
        expected_results: [
                            {
                              limit:  10,
                              data:   (0..499).to_a,
                            },
                            {
                              limit:  250,
                              data:   (0..499).to_a,
                            },
                            {
                              limit:  499,
                              data:   (0..498).to_a,
                            },
                            {
                              limit:  500,
                              data:   (0..499).to_a,
                            },
                            {
                              limit:  501,
                              data:   [],
                            },
                          ]
      },
      {
        endpoint:         @client.resource( :RSpecEvenNumber, 1),
        expected_results: [
                            {
                              limit:  10,
                              data:   (0..498).step(2).to_a
                            },
                            {
                              limit:  249,
                              data:   (0..496).step(2).to_a
                            },
                            {
                              limit:  250,
                              data:   (0..498).step(2).to_a
                            },
                            {
                              limit:  251,
                              data:   []
                            },
                          ]
      },
      {
        endpoint:         @client.resource( :RSpecOddNumber, 1),
        expected_results: [
                            {
                              limit:  10,
                              data:   (1..499).step(2).to_a
                            },
                            {
                              limit:  249,
                              data:   (1..497).step(2).to_a
                            },
                            {
                              limit:  250,
                              data:   (1..499).step(2).to_a
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
          @client.resource( :RSpecNumber, 1),
          @client.resource( :RSpecEvenNumber, 1),
          @client.resource( :RSpecOddNumber, 1),
      ]

      endpoints.each do | endpoint |
        expect {
          endpoint.list.enumerate_all
        }.to raise_exception( RuntimeError, 'Must provide a block to enumerate_all' )
      end

    end

  end

end
