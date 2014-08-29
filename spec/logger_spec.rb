require 'spec_helper'
require 'api_tools/logger'

describe ApiTools::Logger do

  it 'should return a nil logger by default' do
    expect(ApiTools::Logger::logger).to be(nil)
  end

  it 'should set logger' do
    ApiTools::Logger::logger = 'onetwothree'
    expect(ApiTools::Logger::logger).to eq('onetwothree')
  end

  describe 'when a logger is defined' do
    before do
      @logger = double()
      ApiTools::Logger::logger = @logger
    end

    it 'should get debug logger' do
      expect(@logger).to receive(:debug).with([1,2,3]).and_return 'one'
      expect(ApiTools::Logger::debug(1,2,3)).to eq('one')
    end
    it 'should get info logger' do
      expect(@logger).to receive(:info).with([1,2,3]).and_return 'two'
      expect(ApiTools::Logger::info(1,2,3)).to eq('two')
    end
    it 'should get error logger' do
      expect(@logger).to receive(:error).with([1,2,3]).and_return 'three'
      expect(ApiTools::Logger::error(1,2,3)).to eq('three')
    end
  end

  describe 'when a logger is not defined' do
    before do
      ApiTools::Logger::logger = nil
    end

    it 'should get debug logger' do
      expect($stdout).to receive(:puts).with([1,2,3]).and_return 'one'
      expect(ApiTools::Logger::debug(1,2,3)).to eq('one')
    end
    it 'should get info logger' do
      expect($stdout).to receive(:puts).with([1,2,3]).and_return 'two'
      expect(ApiTools::Logger::info(1,2,3)).to eq('two')
    end
    it 'should get error logger' do
      expect($stderr).to receive(:puts).with([1,2,3]).and_return 'three'
      expect(ApiTools::Logger::error(1,2,3)).to eq('three')
    end
  end
end