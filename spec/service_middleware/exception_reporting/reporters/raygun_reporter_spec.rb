require 'spec_helper'
require 'airbrake'

# This doesn't test the Raygun gem / configuration itself - just check that
# the appropriate Raygun method gets called.

describe Hoodoo::ServiceMiddleware::ExceptionReporting::RaygunReporter do

  before :each do
    Hoodoo::ServiceMiddleware::ExceptionReporting.add( described_class )
  end

  after :each do
    Hoodoo::ServiceMiddleware::ExceptionReporting.wait()
    Hoodoo::ServiceMiddleware::ExceptionReporting.remove( described_class )
  end

  it 'calls Raygun' do
    ex = RuntimeError.new( 'A' )
    expect( Raygun ).to receive( :track_exception ).once.with( ex, nil )
    Hoodoo::ServiceMiddleware::ExceptionReporting.report( ex )
  end
end
