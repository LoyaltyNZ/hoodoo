require 'spec_helper'

describe ApiTools::Communicators::Slow do
  it 'complains if #communicate is called directly' do
    expect {
      ApiTools::Communicators::Slow.new.communicate( {} )
    }.to raise_error( RuntimeError )
  end

  it 'does not complain if #dropped is called directly' do
    expect {
      ApiTools::Communicators::Slow.new.dropped( 1 )
    }.to_not raise_error()
  end
end
