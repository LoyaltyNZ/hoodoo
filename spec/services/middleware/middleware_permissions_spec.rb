# These tests focus on the way that a resource can declare a
# requirement to gain extra permissions while processing an
# action, that allow it to call other services. The caller's
# inbound session only needs to be able to call the 'otuermost'
# action to succeed.

require 'spec_helper'

# To show Clock, Clock must call Date which must call Time.
#
# (1) These are all in the same app (local inter-resource calls)
# (2) These are each in different apps (remote calls)
#
# Then insofar as possible, (1) and (2) with:
#
# (A) Clock does not request permission for Date
#     - verify that show yields forbidden and date/time not called
#     - grant session permission for date and verify forbidden
#       and time not called
#     - grant permissions through to time and verify 200
#
# (B) Date does not request permission for Time
#     - verify that show yields forbidden, date called, time not
#     - grant permission for time and verify 200
#
# (C) Full request from Date to Time
#     - verify that show yields 200, date and time called
#     - use ASK rather than ALLOW for Date -> Time to test #verify
#
# Because we don't want same-named resources or same-path resources
# running concurrently (that counts as platform misconfiguration),
# we end up with:
#
# * Three Clock resource names and endpoints - for with-no-added-permissions
#   calls no-added-Date calls Time; with-permissions calls no-added-Date
#   calls Time; and with-permissions calls with-added-Date calls Time.
#
# * Thus two Date names and endpoints - with-permissions calls Time and
#   without-permissions calls Time.
#
# * Just one Time resource end endpoint.

##############################################################################
# Implementations
##############################################################################

class RSpecAddPermTestClockCallsDateNoPermsImplementation < Hoodoo::Services::Implementation
  def show( context )
    date_time = context.resource( :RSpecAddPermTestDateNoPerms ).show( 'now' )
    return if date_time.adds_errors_to?( context.response.errors )
    context.response.set_resource( date_time )
  end
end

class RSpecAddPermTestClockImplementation < Hoodoo::Services::Implementation
  def show( context )
    date_time = context.resource( :RSpecAddPermTestDate ).show( 'now' )
    return if date_time.adds_errors_to?( context.response.errors )
    context.response.set_resource( date_time )
  end
end

class RSpecAddPermTestDateImplementation < Hoodoo::Services::Implementation
  def show( context )
    time = context.resource( :RSpecAddPermTestTime ).show( 'now' )
    return if time.adds_errors_to?( context.response.errors )
    context.response.set_resource( { 'date' => '1999-12-31', 'time' => time[ 'time' ] } )
  end
end

class RSpecAddPermTestTimeImplementation < Hoodoo::Services::Implementation
  def show( context )
    context.response.set_resource( { 'time' => '23:59:59' } )
  end

  # Using ASK in the interfaces later for this specific case lets us check
  # in tests that the interface's permissions we used when getting through
  # to this implementation, rather than some other route. We have to be
  # expecting #verify and return ALLOW. If we aren't expecting it but it's
  # called anyway, it denis the request to hopefully provoke a test failure.
  #
  # Yes, DENY is the default superclass implementation anyway but explicit
  # code here lets future maintainers read this and know what's happening!
  #
  def verify( context, action )
    Hoodoo::Session::Permissions::DENY
  end
end

##############################################################################
# Interfaces
##############################################################################

class RSpecAddPermTestClockNoPermsCallsDateNoPermsInterface < Hoodoo::Services::Interface
  interface :RSpecAddPermTestClockNoPermsCallsDateNoPerms do
    endpoint :rspec_add_perm_test_clock_no_perms_calls_date_no_perms, RSpecAddPermTestClockCallsDateNoPermsImplementation
    actions :show
  end
end

class RSpecAddPermTestClockCallsDateNoPermsInterface < Hoodoo::Services::Interface
  interface :RSpecAddPermTestClockCallsDateNoPerms do
    endpoint :rspec_add_perm_test_clock_calls_date_no_perms, RSpecAddPermTestClockCallsDateNoPermsImplementation
    actions :show

    additional_permissions_for( :show ) do | p |
      p.set_resource( :RSpecAddPermTestDateNoPerms, :show, Hoodoo::Services::Permissions::ALLOW )
    end
  end
end

class RSpecAddPermTestClockInterface < Hoodoo::Services::Interface
  interface :RSpecAddPermTestClock do
    endpoint :rspec_add_perm_test_clocks, RSpecAddPermTestClockImplementation
    actions :show

    additional_permissions_for( :show ) do | p |
      p.set_resource( :RSpecAddPermTestDate, :show, Hoodoo::Services::Permissions::ALLOW )
    end
  end
end

class RSpecAddPermTestDateNoPermsInterface < Hoodoo::Services::Interface
  interface :RSpecAddPermTestDateNoPerms do
    endpoint :rspec_add_perm_test_date_no_perms, RSpecAddPermTestDateImplementation
    actions :show
  end
end

class RSpecAddPermTestDateInterface < Hoodoo::Services::Interface
  interface :RSpecAddPermTestDate do
    endpoint :dates, RSpecAddPermTestDateImplementation
    actions :show

    additional_permissions_for( :show ) do | p |
      p.set_resource( :RSpecAddPermTestTime, :show, Hoodoo::Services::Permissions::ASK )
    end
  end
end

class RSpecAddPermTestTimeInterface < Hoodoo::Services::Interface
  interface :RSpecAddPermTestTime do
    endpoint :rspec_add_perm_test_times, RSpecAddPermTestTimeImplementation
    actions :show
  end
end

##############################################################################
# Service applications for local inter-resource calls
##############################################################################

# (See earlier) (A) Clock does not request permission for Date

class RSpecAddPermTestClockServiceA < Hoodoo::Services::Service
  comprised_of RSpecAddPermTestClockNoPermsCallsDateNoPermsInterface,
               RSpecAddPermTestDateNoPermsInterface,
               RSpecAddPermTestTimeInterface
end

# (See earlier) (B) Date does not request permission for Time

class RSpecAddPermTestClockServiceB < Hoodoo::Services::Service
  comprised_of RSpecAddPermTestClockCallsDateNoPermsInterface,
               RSpecAddPermTestDateNoPermsInterface,
               RSpecAddPermTestTimeInterface
end

# (See earlier) (C) Full request from Date to Time

class RSpecAddPermTestClockServiceC < Hoodoo::Services::Service
  comprised_of RSpecAddPermTestClockInterface,
               RSpecAddPermTestDateInterface,
               RSpecAddPermTestTimeInterface
end

##############################################################################
# Service applications for remote inter-resource calls
##############################################################################

class RSpecAddPermTestClockNoPermsCallsDateNoPermsService < Hoodoo::Services::Service
  comprised_of RSpecAddPermTestClockNoPermsCallsDateNoPermsInterface
end

class RSpecAddPermTestClockCallsDateNoPermsService < Hoodoo::Services::Service
  comprised_of RSpecAddPermTestClockCallsDateNoPermsInterface
end

class RSpecAddPermTestClockService < Hoodoo::Services::Service
  comprised_of RSpecAddPermTestClockInterface
end

class RSpecAddPermTestDateNoPermsService < Hoodoo::Services::Service
  comprised_of RSpecAddPermTestDateNoPermsInterface
end

class RSpecAddPermTestDateService < Hoodoo::Services::Service
  comprised_of RSpecAddPermTestDateInterface
end

class RSpecAddPermTestTimeService < Hoodoo::Services::Service
  comprised_of RSpecAddPermTestTimeInterface
end

describe Hoodoo::Services::Middleware do

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

    # Grant top-level access to all of the Clock endpoints

    @session.permissions = Hoodoo::Services::Permissions.new
    @session.permissions.set_resource(
      :RSpecAddPermTestClockNoPermsCallsDateNoPerms,
      :show,
      Hoodoo::Services::Permissions::ALLOW
    )
    @session.permissions.set_resource(
      :RSpecAddPermTestClockCallsDateNoPerms,
      :show,
      Hoodoo::Services::Permissions::ALLOW
    )
    @session.permissions.set_resource(
      :RSpecAddPermTestClock,
      :show,
      Hoodoo::Services::Permissions::ALLOW
    )

    @old_test_session = Hoodoo::Services::Middleware.test_session()
    Hoodoo::Services::Middleware.set_test_session( @session )

    Hoodoo::Services::Session::MockDalliClient.reset()
  end

  after :each do
    Hoodoo::Services::Middleware.set_test_session( @old_test_session )
  end

  ############################################################################
  # Local inter-resource calls
  ############################################################################

  context 'with local resources and' do

    before :all do
      Hoodoo::Services::Middleware.flush_services_for_test()
    end

    context 'Clock with no extra permissions for Date or Time' do
      def app
        Rack::Builder.new do
          use Hoodoo::Services::Middleware
          run RSpecAddPermTestClockServiceA.new
        end
      end

      it 'cannot call #show in Date or Time by default' do
        expect_any_instance_of(RSpecAddPermTestClockCallsDateNoPermsImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to_not receive( :show )
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to_not receive( :show )

        get '/v1/rspec_add_perm_test_clock_no_perms_calls_date_no_perms/any', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect( last_response.status ).to eq( 403 )

        result = JSON.parse( last_response.body )
        expect( result[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.forbidden' )
        expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
      end

      it 'cannot call #show in Time if session only grants Date access' do
        @session.permissions.set_resource(
          :RSpecAddPermTestDateNoPerms,
          :show,
          Hoodoo::Services::Permissions::ALLOW
        )

        expect_any_instance_of(RSpecAddPermTestClockCallsDateNoPermsImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to_not receive( :show )

        get '/v1/rspec_add_perm_test_clock_no_perms_calls_date_no_perms/any', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect( last_response.status ).to eq( 403 )

        result = JSON.parse( last_response.body )
        expect( result[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.forbidden' )
        expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
      end

      it 'can call #show if session grants Date and Time access' do
        @session.permissions.set_resource(
          :RSpecAddPermTestDateNoPerms,
          :show,
          Hoodoo::Services::Permissions::ALLOW
        )

        @session.permissions.set_resource(
          :RSpecAddPermTestTime,
          :show,
          Hoodoo::Services::Permissions::ALLOW
        )

        expect_any_instance_of(RSpecAddPermTestClockCallsDateNoPermsImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to_not receive( :verify )

        get '/v1/rspec_add_perm_test_clock_no_perms_calls_date_no_perms/any', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect( last_response.status ).to eq( 200 )

        result = JSON.parse( last_response.body )
        expect( result ).to eq( { 'date' => '1999-12-31', 'time' => '23:59:59' } )
      end
    end

    context 'Clock with extra permissions for Date but no extra permissions for Time' do
      def app
        Rack::Builder.new do
          use Hoodoo::Services::Middleware
          run RSpecAddPermTestClockServiceB.new
        end
      end

      it 'cannot call #show in Time by default' do
        expect_any_instance_of(RSpecAddPermTestClockCallsDateNoPermsImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to_not receive( :show )

        get '/v1/rspec_add_perm_test_clock_calls_date_no_perms/any', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect( last_response.status ).to eq( 403 )

        result = JSON.parse( last_response.body )
        expect( result[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.forbidden' )
        expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
      end

      it 'can call #show if session only grants Time access' do
        @session.permissions.set_resource(
          :RSpecAddPermTestTime,
          :show,
          Hoodoo::Services::Permissions::ALLOW
        )

        expect_any_instance_of(RSpecAddPermTestClockCallsDateNoPermsImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to_not receive( :verify )

        get '/v1/rspec_add_perm_test_clock_calls_date_no_perms/any', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect( last_response.status ).to eq( 200 )

        result = JSON.parse( last_response.body )
        expect( result ).to eq( { 'date' => '1999-12-31', 'time' => '23:59:59' } )
      end
    end

    context 'Clock with extra permissions for Date and Time' do
      def app
        Rack::Builder.new do
          use Hoodoo::Services::Middleware
          run RSpecAddPermTestClockServiceC.new
        end
      end

      it 'can call #show without any extra session permissions' do
        expect_any_instance_of(RSpecAddPermTestClockImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to receive( :verify ).with( anything(), :show ).and_return( Hoodoo::Services::Permissions::ALLOW )

        get '/v1/rspec_add_perm_test_clocks/any', nil, { 'CONTENT_TYPE' => 'application/json; charset=utf-8' }
        expect( last_response.status ).to eq( 200 )

        result = JSON.parse( last_response.body )
        expect( result ).to eq( { 'date' => '1999-12-31', 'time' => '23:59:59' } )
      end
    end
  end

  ############################################################################
  # Remote inter-resource calls
  ############################################################################

  context 'with remote resources and' do

    before :all do
      Hoodoo::Services::Middleware.flush_services_for_test()

      @port_clock_no_perms_calls_date_no_perms = spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestClockNoPermsCallsDateNoPermsService )
      @port_clock_calls_date_no_perms = spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestClockCallsDateNoPermsService )
      @port_clock = spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestClockService )

      spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestDateNoPermsService )
      spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestDateService )
      spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestTimeService )
    end

    context 'Clock with no extra permissions for Date or Time' do
      it 'cannot call #show in Date or Time by default' do
        expect_any_instance_of(RSpecAddPermTestClockCallsDateNoPermsImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to_not receive( :show )
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to_not receive( :show )

        response = spec_helper_http(
          :path => '/v1/rspec_add_perm_test_clock_no_perms_calls_date_no_perms/any',
          :port => @port_clock_no_perms_calls_date_no_perms
        )
        expect( response.code ).to eq( '403' )

        result = JSON.parse( response.body )
        expect( result[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.forbidden' )
        expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
      end

      it 'cannot call #show in Time if session only grants Date access' do
        @session.permissions.set_resource(
          :RSpecAddPermTestDateNoPerms,
          :show,
          Hoodoo::Services::Permissions::ALLOW
        )

        expect_any_instance_of(RSpecAddPermTestClockCallsDateNoPermsImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to_not receive( :show )

        response = spec_helper_http(
          :path => '/v1/rspec_add_perm_test_clock_no_perms_calls_date_no_perms/any',
          :port => @port_clock_no_perms_calls_date_no_perms
        )
        expect( response.code ).to eq( '403' )

        result = JSON.parse( response.body )
        expect( result[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.forbidden' )
        expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
      end

      it 'can call #show if session grants Date and Time access' do
        @session.permissions.set_resource(
          :RSpecAddPermTestDateNoPerms,
          :show,
          Hoodoo::Services::Permissions::ALLOW
        )

        @session.permissions.set_resource(
          :RSpecAddPermTestTime,
          :show,
          Hoodoo::Services::Permissions::ALLOW
        )

        expect_any_instance_of(RSpecAddPermTestClockCallsDateNoPermsImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to_not receive( :verify )

        response = spec_helper_http(
          :path => '/v1/rspec_add_perm_test_clock_no_perms_calls_date_no_perms/any',
          :port => @port_clock_no_perms_calls_date_no_perms
        )
        expect( response.code ).to eq( '200' )

        result = JSON.parse( response.body )
        expect( result ).to eq( { 'date' => '1999-12-31', 'time' => '23:59:59' } )
      end
    end

    context 'Clock with extra permissions for Date but no extra permissions for Time' do
      it 'cannot call #show in Time by default' do
        expect_any_instance_of(RSpecAddPermTestClockCallsDateNoPermsImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to_not receive( :show )

        response = spec_helper_http(
          :path => '/v1/rspec_add_perm_test_clock_calls_date_no_perms/any',
          :port => @port_clock_calls_date_no_perms
        )
        expect( response.code ).to eq( '403' )

        result = JSON.parse( response.body )
        expect( result[ 'errors' ][ 0 ][ 'code' ] ).to eq( 'platform.forbidden' )
        expect( result[ 'errors' ][ 0 ][ 'message' ] ).to eq( 'Action not authorized' )
      end

      it 'can call #show if session only grants Time access' do
        @session.permissions.set_resource(
          :RSpecAddPermTestTime,
          :show,
          Hoodoo::Services::Permissions::ALLOW
        )

        expect_any_instance_of(RSpecAddPermTestClockCallsDateNoPermsImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to_not receive( :verify )

        response = spec_helper_http(
          :path => '/v1/rspec_add_perm_test_clock_calls_date_no_perms/any',
          :port => @port_clock_calls_date_no_perms
        )
        expect( response.code ).to eq( '200' )

        result = JSON.parse( response.body )
        expect( result ).to eq( { 'date' => '1999-12-31', 'time' => '23:59:59' } )
      end
    end

    context 'Clock with extra permissions for Date and Time' do
      it 'can call #show without any extra session permissions' do
        expect_any_instance_of(RSpecAddPermTestClockImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestDateImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to receive( :show ).once.and_call_original
        expect_any_instance_of(RSpecAddPermTestTimeImplementation).to receive( :verify ).with( anything(), :show ).and_return( Hoodoo::Services::Permissions::ALLOW )

        response = spec_helper_http(
          :path => '/v1/rspec_add_perm_test_clocks/any',
          :port => @port_clock
        )
        expect( response.code ).to eq( '200' )

        result = JSON.parse( response.body )
        expect( result ).to eq( { 'date' => '1999-12-31', 'time' => '23:59:59' } )
      end
    end
  end
end
