require 'spec_helper'

describe Hoodoo::Services::Middleware::Endpoint::AugmentedHash do

  # However much the class arrangement might change in future, ultimately the
  # class must inherit from Hash and support a basic interface expected by
  # any AugmentedBase "client".
  #
  it 'instantiates correctly' do
    expect( described_class.new ).to be_a( Hash )
    expect( described_class.new.respond_to?( :adds_errors_to? ) ).to eq( true )
    expect( described_class.new.respond_to?( :set_platform_errors ) ).to eq( true )
    expect( described_class.new.respond_to?( :platform_errors ) ).to eq( true )
  end
end
