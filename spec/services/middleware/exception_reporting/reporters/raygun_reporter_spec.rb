require 'spec_helper'
require 'airbrake'

# This doesn't test the Raygun gem / configuration itself - just check that
# the appropriate Raygun method gets called.

describe Hoodoo::Services::Middleware::ExceptionReporting::RaygunReporter do

  before :each do
    Hoodoo::Services::Middleware::ExceptionReporting.add( described_class )
  end

  after :each do
    Hoodoo::Services::Middleware::ExceptionReporting.wait()
    Hoodoo::Services::Middleware::ExceptionReporting.remove( described_class )
  end

  it 'calls Raygun' do
    ex = RuntimeError.new( 'A' )
    expect( Raygun ).to receive( :track_exception ).once.with( ex, nil )
    Hoodoo::Services::Middleware::ExceptionReporting.report( ex )
  end
end
