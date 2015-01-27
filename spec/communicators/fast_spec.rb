require 'spec_helper'

describe Hoodoo::Communicators::Fast do
  it 'complains if called directly' do
    expect {
      Hoodoo::Communicators::Fast.new.communicate( {} )
    }.to raise_error( RuntimeError )
  end
end
