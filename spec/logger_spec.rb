require 'spec_helper'
require 'api_tools/logger'

describe ApiTools::Logger do

  it 'should return the spec helper test logger by default' do
    expect(ApiTools::Logger::logger).to be(StdErrTestLogger)
  end

  it 'should set logger' do
    ApiTools::Logger::logger = nil
    expect(ApiTools::Logger::logger).to be_nil
    ApiTools::Logger::logger = StdErrTestLogger
    expect(ApiTools::Logger::logger).to eq(StdErrTestLogger)
  end

  describe 'when a bad logger is defined' do
    it 'raises an exception' do
      expect {
        logger = double()
        expect(logger).to receive(:<=).and_return(true)
        ApiTools::Logger::logger = logger
      }.to raise_exception( RuntimeError )
    end
  end

  describe 'when a logger is defined' do
    before do
      @logger = double()
      allow(@logger).to receive(:<=).and_return(false)
      ApiTools::Logger::logger = @logger
    end

    it 'should get debug logger' do
      expect(@logger).to receive(:debug).with(:Middleware, :log, {'_data'=>[1,2,3]}.inspect).and_return 'one'
      expect(ApiTools::Logger::debug(1,2,3)).to eq('one')
    end
    it 'should get info logger' do
      expect(@logger).to receive(:info).with(:Middleware, :log, {'_data'=>[2,3,4]}.inspect).and_return 'two'
      expect(ApiTools::Logger::info(2,3,4)).to eq('two')
    end
    it 'should get info logger' do
      expect(@logger).to receive(:warn).with(:Middleware, :log, {'_data'=>[3,4,5]}.inspect).and_return 'three'
      expect(ApiTools::Logger::warn(3,4,5)).to eq('three')
    end
    it 'should get error logger' do
      expect(@logger).to receive(:error).with(:Middleware, :log, {'_data'=>[4,5,6]}.inspect).and_return 'four'
      expect(ApiTools::Logger::error(4,5,6)).to eq('four')
    end
  end

  describe 'when a logger is not defined' do
    before do
      ApiTools::Logger::logger = nil
    end

    it 'should get debug logger' do
      expect($stdout).to receive(:puts).with('DEBUG', :Middleware, :log, {'_data'=>[1,2,3]}.inspect).and_return 'one'
      expect(ApiTools::Logger::debug(1,2,3)).to eq('one')
    end
    it 'should get info logger' do
      expect($stdout).to receive(:puts).with('INFO', :Middleware, :log, {'_data'=>[2,3,4]}.inspect).and_return 'two'
      expect(ApiTools::Logger::info(2,3,4)).to eq('two')
    end
    it 'should get warn logger' do
      expect($stdout).to receive(:puts).with('WARN', :Middleware, :log, {'_data'=>[3,4,5]}.inspect).and_return 'three'
      expect(ApiTools::Logger::warn(3,4,5)).to eq('three')
    end
    it 'should get error logger' do
      expect($stdout).to receive(:puts).with('ERROR', :Middleware, :log, {'_data'=>[4,5,6]}.inspect).and_return 'four'
      expect(ApiTools::Logger::error(4,5,6)).to eq('four')
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
      expect($stdout).to receive(:puts)
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

      expect($stdout).to receive(:puts)
      ApiTools::Logger::error(1)
    end
  end
end