require 'spec_helper'

describe ApiTools::Logger do
  context 'basics' do
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
  end

  context 'pool operations' do
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

  context 'structured logging' do
  end

  context 'legacy logging' do
  end
end
