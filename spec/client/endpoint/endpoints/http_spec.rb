require 'spec_helper'

# Much of this class gets nontrivial coverage from middleware tests, which
# existed before the refactor of code from there, into endpoints.
#
# This file just picks up the loose ends.

describe Hoodoo::Client::Endpoint::HTTP do

  it 'complains if instantiated with the wrong discovery result type' do
    expect {
      described_class.new( :Anything, 1, { :discovery_result => OpenStruct.new } )
    }.to raise_error( RuntimeError, "Hoodoo::Client::Endpoint::HTTP must be configured with a Hoodoo::Services::Discovery::ForHTTP instance - got 'OpenStruct'" )
  end

end
