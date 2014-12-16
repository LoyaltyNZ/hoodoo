require 'spec_helper'

describe ApiTools::Logger::FastWriter do

  # Nothing much to do here as code is covered by logger_spec.rb. Testing
  # both file and stream writers tests the fast and slow code since they are
  # subclasses of that. Thus, the only thing we make sure of here is that the
  # two things remain subclasses of "the expected thing" so that test coverage
  # remains good.
  #
  it 'is used by the expected writer' do
    expect( ApiTools::Logger::StreamWriter < ApiTools::Logger::FastWriter ).to eq( true )
  end

end
