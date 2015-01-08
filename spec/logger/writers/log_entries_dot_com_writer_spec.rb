require 'spec_helper'

describe ApiTools::Logger::LogEntriesDotComWriter do

  let( :example_token ) do
    # https://logentries.com/doc/input-token/
    '2bfbea1e-10c3-4419-bdad-7e6435882e1f'
  end

  before( :each ) do
    @instance = described_class.new( example_token() )
    @logger = @instance.class.class_variable_get( '@@logger' )
  end

  it 'calls the "Le" class instance' do
    expect( @logger ).to receive( :info ).once
    @instance.report( :info, :b, :c, :d )
  end

  it 'converts unrecognised debug levels to "unknown"' do
    expect( @logger ).to receive( :unknown ).once
    @instance.report( :a, :b, :c, :d )
  end
end
