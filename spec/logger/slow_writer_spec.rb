require 'spec_helper'

describe ApiTools::Logger::SlowWriter do

  # See fast_writer_spec.rb comments.
  #
  it 'is used by the expected writer' do
    expect( ApiTools::Logger::FileWriter < ApiTools::Logger::SlowWriter ).to eq( true )
  end

end
