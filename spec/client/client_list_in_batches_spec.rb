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
# Define our service
#
class RSpecNumberService < Hoodoo::Services::Service
  comprised_of RSpecNumberInterface
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
    @endpoint = client.resource( :RSpecNumberTarget, 1)
  end

  it 'acts like a resource' do

    results = @endpoint.list
    expect( results.platform_errors.has_errors? ).to eq( false )
    expect( results.size                        ).to eq( 50)
    expect( results[0]                          ).to eq( { 'number' => 0 } )
    expect( results[-1]                         ).to eq( { 'number' => 49 } )

  end

  it 'serves up paginated results' do

    0.upto( 3 ) do |page|
      results = @endpoint.list( { limit: 250, offset: 250 * page } )
      expect( results.platform_errors.has_errors? ).to eq( false )
      expect( results.size                        ).to eq( 250)
      expect( results[0]                          ).to eq( { 'number' => page * 250 } )
      expect( results[-1]                         ).to eq( { 'number' => (page * 250) + 249 } )
    end

  end

  it 'paginates correctly if we go beyond the last resource' do

    results = @endpoint.list( { limit: 100, offset: 950 } )
    expect( results.platform_errors.has_errors? ).to eq( false )
    expect( results.size                        ).to eq( 50 )
    expect( results[0]                          ).to eq( { 'number' => 950 } )
    expect( results[-1]                         ).to eq( { 'number' => 999 } )

  end

  it 'returns an error when forced' do

    # results = @endpoint.list( { limit: 100, offset: 950 } )
    # expect( results.platform_errors.has_errors? ).to eq( true )

  end

end
