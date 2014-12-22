require 'spec_helper'

describe ApiTools::Logger::FastWriter do

  # Nothing much to do here as code is covered by logger_spec.rb. The only
  # thing we make sure of here is that the stream writer tested there is a
  # subclass of the thing this test would otherwise cover.
  #
  it 'is used by the expected writer' do
    expect( ApiTools::Logger::StreamWriter < described_class ).to eq( true )
  end

  it 'complains about missing subclass implementation' do
    expect {
      ApiTools::Logger::FastWriter.new().report( 1, 2, 3, 4 )
    }.to raise_error( RuntimeError )
  end
end
