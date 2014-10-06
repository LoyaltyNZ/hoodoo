require 'spec_helper.rb'

describe ApiTools::StringInquirer do
  it 'should define implicit methods ending in "?"' do
    greeting = ApiTools::StringInquirer.new( 'hello' )
    expect(greeting.hello?()).to eq(true)
    expect(greeting.hi?()).to eq(false)
  end

  it 'should not define implicit methods that do not end in "?"' do
    greeting = ApiTools::StringInquirer.new( 'hello' )
    expect {
      greeting.hello()
    }.to raise_error(NoMethodError)
  end

  # The above tests don't cause proper coverage according to RCov, so force
  # the issue...
  #
  context 'poke private API for code coverage' do
    it 'should sigh quietly to itself' do
      greeting = ApiTools::StringInquirer.new( 'hello' )
      expect(greeting.send(:respond_to_missing?, :hello?, false)).to eq(true)
      expect(greeting.send(:method_missing, :hello?)).to eq(true)
      expect {
        greeting.send(:method_missing, :hello)
      }.to raise_error(NoMethodError)
    end
  end
end
