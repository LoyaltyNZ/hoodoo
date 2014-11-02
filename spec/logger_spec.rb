require 'spec_helper'
require 'api_tools/logger'

describe ApiTools::Logger do

  it 'should return the spec helper test logger by default' do
    expect(ApiTools::Logger::logger).to be(StdErrTestLogger)
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
    it 'should get info logger' do
      expect(@logger).to receive(:warn).with([1,2,3]).and_return 'two'
      expect(ApiTools::Logger::warn(1,2,3)).to eq('two')
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
      expect($stdout).to receive(:puts).with('DEBUG',[1,2,3]).and_return 'one'
      expect(ApiTools::Logger::debug(1,2,3)).to eq('one')
    end
    it 'should get info logger' do
      expect($stdout).to receive(:puts).with('INFO',[1,2,3]).and_return 'two'
      expect(ApiTools::Logger::info(1,2,3)).to eq('two')
    end
    it 'should get warn logger' do
      expect($stdout).to receive(:puts).with('WARN',[1,2,3]).and_return 'two'
      expect(ApiTools::Logger::warn(1,2,3)).to eq('two')
    end
    it 'should get error logger' do
      expect($stderr).to receive(:puts).with('ERROR',[1,2,3]).and_return 'three'
      expect(ApiTools::Logger::error(1,2,3)).to eq('three')
    end
  end

  describe 'logging levels' do
    before do
      ApiTools::Logger::logger = nil
    end

    it 'should log correctly when level = :debug' do
      ApiTools::Logger::level = :debug

      expect($stdout).to receive(:puts)
      ApiTools::Logger::debug(1)
      expect($stdout).to receive(:puts)
      ApiTools::Logger::info(1)
      expect($stdout).to receive(:puts)
      ApiTools::Logger::warn(1)
      expect($stderr).to receive(:puts)
      ApiTools::Logger::error(1)

      expect(ApiTools::Logger.level).to eq(:debug)
    end

    it 'should log correctly when level = :info' do
      ApiTools::Logger::level = :info

      expect($stdout).not_to receive(:puts)
      ApiTools::Logger::debug(1)
    end

    it 'should log correctly when level = :warn' do
      ApiTools::Logger::level = :warn

      expect($stdout).not_to receive(:puts)
      ApiTools::Logger::debug(1)
      ApiTools::Logger::info(1)
    end

    it 'should always log errors' do
      ApiTools::Logger::level = :invalidValue

      expect($stderr).to receive(:puts)
      ApiTools::Logger::error(1)
    end
  end
end