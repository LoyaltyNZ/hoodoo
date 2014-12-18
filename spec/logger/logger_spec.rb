require 'spec_helper'

describe ApiTools::Logger do

  # ===========================================================================

  context 'basic behaviour' do
    before :each do
      @logger = described_class.new
    end

    it 'has a debug level by default' do
      expect( @logger.level ).to eq( :debug )
    end

    it 'has no writers by default' do
      expect( $stdout ).to_not receive( :puts )
      expect( $stderr ).to_not receive( :puts )

      @logger.error( 'No writers' )
    end

    it 'complains about bad additions' do
      expect {
        @logger.add( Object.new )
      }.to raise_error( RuntimeError )
    end
  end

  # ===========================================================================

  context 'pool operation' do
    before :each do
      @logger   = described_class.new
      @stderr_1 = ApiTools::Logger::StreamWriter.new( $stderr )
      @stderr_2 = ApiTools::Logger::StreamWriter.new( $stderr )
      @stderr_3 = ApiTools::Logger::StreamWriter.new( $stderr )

      @logger.add( @stderr_1 )
      @logger.add( @stderr_2 )
      @logger.add( @stderr_3 )
    end

    it 'calls added instances' do
      expect( @stderr_1 ).to receive( :report ).once
      expect( @stderr_2 ).to receive( :report ).once
      expect( @stderr_3 ).to receive( :report ).once
      expect( $stderr ).to_not receive( :puts )

      @logger.error( 'Three instances of StreamWriter' )
    end

    it 'removes requested instances' do
      @logger.remove( @stderr_2 )

      expect( @stderr_1 ).to receive( :report ).once
      expect( @stderr_2 ).to_not receive( :report )
      expect( @stderr_3 ).to receive( :report ).once
      expect( $stderr ).to_not receive( :puts )

      @logger.error( 'Two instances of StreamWriter' )
    end

    it 'removes all instances' do
      @logger.remove_all

      expect( @stderr_1 ).to_not receive( :report )
      expect( @stderr_2 ).to_not receive( :report )
      expect( @stderr_3 ).to_not receive( :report )
      expect( $stderr ).to_not receive( :puts )

      @logger.error( 'No instances of StreamWriter' )
    end
  end

  # ===========================================================================

  context 'structured logging' do
    before :each do
      @logger = described_class.new
      @writer = ApiTools::Logger::StreamWriter.new( $stderr )
      @logger.add( @writer )
    end

    it 'makes a structured log entry' do
      expect(@writer).to receive(:report).with(:debug, :ComponentName, :code_value, {'_data'=>[1,2,3]})
      @logger.report(
        :debug,
        :ComponentName,
        :code_value,
        {'_data'=>[1,2,3]}
      )
    end

    it 'obeys debug log level' do
      expect(@writer).to receive(:report).once

      @logger.level = :debug
      @logger.report(:debug, :comp, :code, {})

      expect(@writer).to_not receive(:report)

      @logger.level = :info
      @logger.report(:debug, :comp, :code, {})
      @logger.level = :warn
      @logger.report(:debug, :comp, :code, {})
      @logger.level = :error
      @logger.report(:debug, :comp, :code, {})
    end

    it 'obeys info log level' do
      expect(@writer).to receive(:report).exactly(2).times

      @logger.level = :debug
      @logger.report(:info, :comp, :code, {})
      @logger.level = :info
      @logger.report(:info, :comp, :code, {})

      expect(@writer).to_not receive(:report)

      @logger.level = :warn
      @logger.report(:info, :comp, :code, {})
      @logger.level = :error
      @logger.report(:info, :comp, :code, {})
    end

    it 'obeys warn log level' do
      expect(@writer).to receive(:report).exactly(3).times

      @logger.level = :debug
      @logger.report(:warn, :comp, :code, {})
      @logger.level = :info
      @logger.report(:warn, :comp, :code, {})
      @logger.level = :warn
      @logger.report(:warn, :comp, :code, {})

      expect(@writer).to_not receive(:report)

      @logger.level = :error
      @logger.report(:warn, :comp, :code, {})
    end

    it 'obeys error log level' do
      expect(@writer).to receive(:report).exactly(4).times

      @logger.level = :debug
      @logger.report(:error, :comp, :code, {})
      @logger.level = :info
      @logger.report(:error, :comp, :code, {})
      @logger.level = :warn
      @logger.report(:error, :comp, :code, {})
      @logger.level = :error
      @logger.report(:error, :comp, :code, {})
    end
  end

  # ===========================================================================

  context 'legacy logging' do
    before :each do
      @logger = described_class.new
      @writer = ApiTools::Logger::StreamWriter.new( $stderr )
      @logger.add( @writer )
    end

    it 'makes debug log entry' do
      expect(@writer).to receive(:report).with(:debug, :Middleware, :log, {'_data'=>[1,2,3]})
      @logger.debug(1,2,3)
    end

    it 'makes info log entry' do
      expect(@writer).to receive(:report).with(:info, :Middleware, :log, {'_data'=>[2,3,4]})
      @logger.info(2,3,4)
    end

    it 'makes info log entry' do
      expect(@writer).to receive(:report).with(:warn, :Middleware, :log, {'_data'=>[3,4,5]})
      @logger.warn(3,4,5)
    end

    it 'makes error log entry' do
      expect(@writer).to receive(:report).with(:error, :Middleware, :log, {'_data'=>[4,5,6]})
      @logger.error(4,5,6)
    end

    it 'customises component' do
      logger = described_class.new(:Custom)
      logger.add(@writer)
      expect(@writer).to receive(:report).with(:error, :Custom, :log, {'_data'=>[4,5,6]})
      logger.error(4,5,6)
    end

    it 'obeys debug log level' do
      expect(@writer).to receive(:report).once

      @logger.level = :debug
      @logger.debug( 'data' )

      expect(@writer).to_not receive(:report)

      @logger.level = :info
      @logger.debug( 'data' )
      @logger.level = :warn
      @logger.debug( 'data' )
      @logger.level = :error
      @logger.debug( 'data' )
    end

    it 'obeys info log level' do
      expect(@writer).to receive(:report).exactly(2).times

      @logger.level = :debug
      @logger.info( 'data' )
      @logger.level = :info
      @logger.info( 'data' )

      expect(@writer).to_not receive(:report)

      @logger.level = :warn
      @logger.info( 'data' )
      @logger.level = :error
      @logger.info( 'data' )
    end

    it 'obeys warn log level' do
      expect(@writer).to receive(:report).exactly(3).times

      @logger.level = :debug
      @logger.warn( 'data' )
      @logger.level = :info
      @logger.warn( 'data' )
      @logger.level = :warn
      @logger.warn( 'data' )

      expect(@writer).to_not receive(:report)

      @logger.level = :error
      @logger.warn( 'data' )
    end

    it 'obeys error log level' do
      expect(@writer).to receive(:report).exactly(4).times

      @logger.level = :debug
      @logger.error( 'data' )
      @logger.level = :info
      @logger.error( 'data' )
      @logger.level = :warn
      @logger.error( 'data' )
      @logger.level = :error
      @logger.error( 'data' )
    end
  end
end
