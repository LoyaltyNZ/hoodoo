require 'spec_helper'
require 'raygun4ruby'

# This doesn't test the Airbrake gem / configuration itself - Airbrake has its
# own test suite - just check that the appropriate Airbrake method gets called.

describe ApiTools::ServiceMiddleware::ExceptionReporting::AirbrakeReporter do

  before :each do
    ApiTools::ServiceMiddleware::ExceptionReporting.add( described_class )
  end

  after :each do
    ApiTools::ServiceMiddleware::ExceptionReporting.wait()
    ApiTools::ServiceMiddleware::ExceptionReporting.remove( described_class )
  end

  it 'calls Airbrake' do
    ApiTools::ServiceMiddleware::ExceptionReporting.add( described_class )
    ex = RuntimeError.new( 'A' )
    expect( Airbrake ).to receive( :notify_or_ignore ).once.with( ex, { :rack_env => nil } )
    ApiTools::ServiceMiddleware::ExceptionReporting.report( ex )
  end
end
