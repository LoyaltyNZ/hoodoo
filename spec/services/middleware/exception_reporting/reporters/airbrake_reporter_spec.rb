require 'spec_helper'
require 'raygun4ruby'

# This doesn't test the Airbrake gem / configuration itself - just check that
# the appropriate Airbrake method gets called.

describe Hoodoo::ServiceMiddleware::ExceptionReporting::AirbrakeReporter do

  before :each do
    Hoodoo::ServiceMiddleware::ExceptionReporting.add( described_class )
  end

  after :each do
    Hoodoo::ServiceMiddleware::ExceptionReporting.wait()
    Hoodoo::ServiceMiddleware::ExceptionReporting.remove( described_class )
  end

  it 'calls Airbrake' do
    Hoodoo::ServiceMiddleware::ExceptionReporting.add( described_class )
    ex = RuntimeError.new( 'A' )
    expect( Airbrake ).to receive( :notify_or_ignore ).once.with( ex, { :rack_env => nil } )
    Hoodoo::ServiceMiddleware::ExceptionReporting.report( ex )
  end
end
