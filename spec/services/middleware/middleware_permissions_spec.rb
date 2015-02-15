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

##############################################################################
# Implementations
##############################################################################

class RSpecAddPermTestClockImplementation < Hoodoo::Services::Implementation
  def show( context )
    endpoint = context.resource( :Date )
    date_time = endpoint.show( 'now' )
    context.set_resource( date_time )
  end
end

class RSpecAddPermTestDateImplementation < Hoodoo::Services::Implementation
  def show( context )
    endpoint = context.resource( :Time )
    time = endpoint.show( 'now' )
    context.set_resource( { 'date' => '1999-12-31', 'time' => time[ 'time' ] } )
  end
end

class RSpecAddPermTestTimeImplementation < Hoodoo::Services::Implementation
  def show( context )
    context.set_resource( { 'time' => '23:59:59' } )
  end
end

##############################################################################
# Interfaces
##############################################################################

class RSpecAddPermTestClockNoPermsInterface < Hoodoo::Services::Interface
  interface :Clock do
    endpoint :clocks, RSpecAddPermTestClockImplementation
    actions :show
  end
end

class RSpecAddPermTestClockInterface < Hoodoo::Services::Interface
  interface :Clock do
    endpoint :clocks, RSpecAddPermTestClockImplementation
    actions :show

    additional_permissions_for( :show ) do | p |
      p.set_resource( :Date, :show, Hoodoo::Services::Permissions::ALLOW )
    end
  end
end

class RSpecAddPermTestDateNoPermsInterface < Hoodoo::Services::Interface
  interface :Date do
    endpoint :dates, RSpecAddPermTestDateImplementation
    actions :show
  end
end

class RSpecAddPermTestDateInterface < Hoodoo::Services::Interface
  interface :Date do
    endpoint :dates, RSpecAddPermTestDateImplementation
    actions :show

    additional_permissions_for( :show ) do | p |
      p.set_resource( :Time, :show, Hoodoo::Services::Permissions::ASK )
    end
  end
end

class RSpecAddPermTestTimeInterface < Hoodoo::Services::Interface
  interface :Time do
    endpoint :times, RSpecAddPermTestTimeImplementation
    actions :show
  end
end

##############################################################################
# Service applications for local inter-resource calls
##############################################################################

# (See earlier) (A) Clock does not request permission for Date

class RSpecAddPermTestClockServiceA < Hoodoo::Services::Application
  comprised_of RSpecAddPermTestClockNoPermsInterface,
               RSpecAddPermTestDateNoPermsInterface,
               RSpecAddPermTestTimeInterface
end

# (See earlier) (B) Date does not request permission for Time

class RSpecAddPermTestClockServiceB < Hoodoo::Services::Application
  comprised_of RSpecAddPermTestClockNoPermsInterface,
               RSpecAddPermTestDateInterface,
               RSpecAddPermTestTimeInterface
end

# (See earlier) (C) Full request from Date to Time

class RSpecAddPermTestClockServiceC < Hoodoo::Services::Application
  comprised_of RSpecAddPermTestClockInterface,
               RSpecAddPermTestDateInterface,
               RSpecAddPermTestTimeInterface
end

##############################################################################
# Service applications for remote inter-resource calls
##############################################################################

class RSpecAddPermTestClockNoPermsService < Hoodoo::Services::Application
  comprised_of RSpecAddPermTestClockNoPermsInterface
end

class RSpecAddPermTestClockService < Hoodoo::Services::Application
  comprised_of RSpecAddPermTestClockInterface
end

class RSpecAddPermTestDateNoPermsService < Hoodoo::Services::Application
  comprised_of RSpecAddPermTestDateNoPermsInterface
end

class RSpecAddPermTestDateService < Hoodoo::Services::Application
  comprised_of RSpecAddPermTestDateInterface
end

class RSpecAddPermTestTimeService < Hoodoo::Services::Application
  comprised_of RSpecAddPermTestTimeInterface
end

##############################################################################
# Local inter-resource calls
##############################################################################

describe Hoodoo::Services::Middleware do
end

##############################################################################
# Remote inter-resource calls
##############################################################################

describe Hoodoo::Services::Middleware do
  before :all do
    @port_clock_no_perms = spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestClockNoPermsService )
    @port_clock          = spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestClockService        )
    @port_date_no_perms  = spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestDateNoPermsService  )
    @port_date           = spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestDateService         )
    @port_time           = spec_helper_start_svc_app_in_thread_for( RSpecAddPermTestTimeService         )
  end
end
