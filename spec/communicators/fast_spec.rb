require 'spec_helper'

describe ApiTools::Communicators::Fast do
  it 'complains if called directly' do
    expect {
      ApiTools::Communicators::Fast.new.communicate( {} )
    }.to raise_error( RuntimeError )
  end
end
