# Testing a local endpoint that makes calls to a remote endpoint

(PROVISIONAL)

This document describes how to set up a mock remote service (resource endpoint) so your tests can be self-contained and simulate a variety of unusual return types / errors / etc. from the remote endpoint in question.

```ruby
# Suppose I have a service which makes an *external*/remote
# inter-resource call to a resource called "Clock".
#
# Using stuff in Hoodoo's spec_helper.rb, here's how to define
# a mock Clock resource endpoint, stand it up in its own HTTP
# service and allow calls to it.

describe SomeLocalServiceClass do

  # Absolute bare minimum set of classes to define a Clock -
  # make sure the ClockInterface defines the correct resource
  # name, endpoint and version.
  #
  class ClockImplementation < Hoodoo::Services::Implementation
  end

  class ClockInterface < Hoodoo::Services::Interface
    interface :Clock do
      endpoint :clocks, ClockImplementation
    end
  end

  class ClockService < Hoodoo::Services::Service
    comprised_of ClockInterface
  end

  # This bit is kind of optional but may be useful
  #
  before :each do
    @session_id     = Hoodoo::UUID.generate
    @caller_id      = Hoodoo::UUID.generate
    @caller_version = 1
    @session        = Hoodoo::Services::Session.new( {
      :session_id     => @session_id,
      :memcached_host => '0.0.0.0:0',
      :caller_id      => @caller_id,
      :caller_version => @caller_version
    } )

    @session.permissions = Hoodoo::Services::Permissions.new

    # ...then call @session.permissions.set_resource to grant
    # just the *LOCAL* service you're testing with enough
    # permissions. No permissions for Clock.
    #
    @old_test_session = Hoodoo::Services::Middleware.test_session()
    Hoodoo::Services::Middleware.set_test_session( @session )
  end

  after :each do
    Hoodoo::Services::Middleware.set_test_session( @old_test_session )
  end

  # Here's where we spin up ClockService inside its own
  # thread under WEBRick. The method called here returns the
  # port number that the service is listening on, but we don't
  # care; the middleware's DRb service will register this new
  # endpoint and thus, when your code-under-test tries to
  # make a remote inter-resource call, the middleware will
  # find the thing you've run here.
  #
  # To be clear: This runs up the *MOCK REMOTE TARGET* thing
  # that you're NOT testing directly.
  #
  before :all do
    spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestClockService )
  end

  context 'inter-resource calls to Clock endpoint' do

    # Define your under-test implementation class as the thing
    # that we'll call using the RSpec DSL locally.
    #
    # To be clear: This "runs up" the *LOCAL SERVICE UNDER TEST*
    # that will make an inter-resource call to the mock remove
    # service started earlier.
    #
    def app
      Rack::Builder.new do
        use Hoodoo::Services::Middleware
        run SomeLocalServiceClass.new
      end
    end

    # The "and_return" block must be a formally correct resource,
    # so perhaps do that by factories and/or the Hoodoo presenters
    # to render yourself some canonical expected 'on success' case
    # for Clock.
    #
    # You'd need to do more advanced things with a block if you
    # wanted to actually get the 'context' object and add errors
    # to it, to simulate the Clock endpoint failing and make sure
    # your calling service then handled that failure case.
    #
    it 'does stuff that requires it to call Clock#show and handles success' do
      expect_any_instance_of( ClockImplementation ).to receive( :show ).and_return( {} )

      get '/v1/resource_you_are_testing', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }

      expect( last_response.status ).to eq( 200 )
      result = JSON.parse( last_response.body )
      # ...etc...
    end
  end
end
```

## Other notes

* Hoodoo's `spec_helper.rb` sets a custom DRb registry port to avoid colliding with the non-test-mode DRb services that might be up on your local machine.

```ruby
ENV[ 'HOODOO_DISCOVERY_BY_DRB_PORT_OVERRIDE' ] = Hoodoo::Utilities.spare_port().to_s()
```

* Shut it down with:

```ruby
config.after( :suite ) do
  drb_uri = Hoodoo::Services::Discovery::ByDRb::DRbServer.uri()
  drb_service = DRbObject.new_with_uri( drb_uri )
  drb_service.stop()
end
```
