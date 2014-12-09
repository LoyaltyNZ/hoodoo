require 'spec_helper'
require 'airbrake'

# This doesn't test the Raygun gem / configuration itself - just check that
# the appropriate Raygun method gets called.

describe ApiTools::ServiceMiddleware::ExceptionReporting::RaygunReporter do

  before :each do
    ApiTools::ServiceMiddleware::ExceptionReporting.add( described_class )
  end

  after :each do
    ApiTools::ServiceMiddleware::ExceptionReporting.wait()
    ApiTools::ServiceMiddleware::ExceptionReporting.remove( described_class )
  end

  it 'calls Raygun' do
    ex = RuntimeError.new( 'A' )
    expect( Raygun ).to receive( :track_exception ).once.with( ex, nil )
    ApiTools::ServiceMiddleware::ExceptionReporting.report( ex )
  end
end
