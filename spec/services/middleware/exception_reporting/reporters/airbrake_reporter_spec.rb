require 'spec_helper'
require 'raygun4ruby'

# This doesn't test the Airbrake gem / configuration itself - just check that
# the appropriate Airbrake method gets called.

describe Hoodoo::Services::Middleware::ExceptionReporting::AirbrakeReporter do

  before :each do
    Hoodoo::Services::Middleware::ExceptionReporting.add( described_class )
  end

  after :each do
    Hoodoo::Services::Middleware::ExceptionReporting.wait()
    Hoodoo::Services::Middleware::ExceptionReporting.remove( described_class )
  end

  it 'calls Airbrake' do
    Hoodoo::Services::Middleware::ExceptionReporting.add( described_class )
    ex = RuntimeError.new( 'A' )
    expect( Airbrake ).to receive( :notify_or_ignore ).once.with( ex, { :rack_env => nil } )
    Hoodoo::Services::Middleware::ExceptionReporting.report( ex )
  end
end
