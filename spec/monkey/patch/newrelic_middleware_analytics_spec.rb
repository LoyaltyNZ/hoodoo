require 'spec_helper.rb'

# This is little more than a coverage exercise.

describe Hoodoo::Monkey::Patch::NewRelicMiddlewareAnalytics do

  class RSpecTestNRMAImplementation < Hoodoo::Services::Implementation
    def list( context ); end
  end

  class RSpecTestNRMAInterface < Hoodoo::Services::Interface
    interface :RSpecTestNRMA do
      endpoint :rspec_test_nrma, RSpecTestNRMAImplementation
    end
  end

  class RSpecTestNRMAService < Hoodoo::Services::Service
    comprised_of RSpecTestNRMAInterface
  end

  def app
    Rack::Builder.new do
      use Hoodoo::Services::Middleware
      run RSpecTestNRMAService.new
    end
  end

  before :all do
    $endpoint_monkey_log_inbound_request_count = 0

    module NewRelic
      module Agent
        extend self
        def add_custom_attributes( params )
          $endpoint_monkey_log_inbound_request_count += 1
        end
      end
    end

    Hoodoo::Monkey.enable( extension_module: Hoodoo::Monkey::Patch::NewRelicMiddlewareAnalytics )
  end

  after :all do
    Hoodoo::Monkey.disable( extension_module: Hoodoo::Monkey::Patch::NewRelicMiddlewareAnalytics )
    Object.send( :remove_const, :NewRelic )
  end

  before :each do
    expect( Hoodoo::Services::Middleware.ancestors ).to include( Hoodoo::Monkey::Patch::NewRelicMiddlewareAnalytics::InstanceExtensions )
  end

  it 'calls the NewRelic patch' do
    get '/v1/rspec_test_nrma', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
    expect( last_response.status ).to eq( 200 )

    # We expect two log calls; secure inbound and normal inbound.
    #
    expect( $endpoint_monkey_log_inbound_request_count ).to eq( 2 )
  end
end
