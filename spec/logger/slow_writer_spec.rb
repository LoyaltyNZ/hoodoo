require 'spec_helper'

describe Hoodoo::Logger::SlowWriter do

  # See fast_writer_spec.rb comments.
  #
  it 'is used by the expected writer' do
    expect( Hoodoo::Logger::FileWriter < described_class ).to eq( true )
  end

  class RSpecTestSlowWriter < Hoodoo::Logger::SlowWriter
    def report( a, b, c, d )
      expectable_hook( a, b, c, d )
    end
  end

  context 'with exceptions' do
    class RSpecTestErrantSlowWriter < Hoodoo::Logger::SlowWriter
      def report( a, b, c, d )
        raise 'I am broken'
      end
    end

    before :each do
      @logger = Hoodoo::Logger.new
      @logger.add( RSpecTestErrantSlowWriter.new )
    end

    it 'logs them' do
      @logger.debug( 'Doh' )
    end
  end

  context 'message dropping' do
    before :each do

      # This sync queue is pushed from the running test and popped from the
      # communicators inside their message handler, so that we can force the
      # communicators to halt "mid-message" by not pushing until we're ready.

      $sync_queue = Queue.new
    end

    before :each do
      @logger = Hoodoo::Logger.new
    end

    class RSpecTestDroppingSlowWriter < Hoodoo::Logger::SlowWriter
      def initialize
        @count = 0
      end

      attr_reader :count

      # This consumes one message then tries to pop a queue item, forcing it
      # to wait for the test code to push. This lets us control completely
      # consistently thread execution, guaranteeing no further processing of
      # log messages until we want to let it run.
      #
      def report( a, b, c, d )
        $sync_queue.pop if @count == 0
        @count += 1
      end
    end

    # Cribbed from the communicators/pool_spec.rb approach, with the same
    # limitations.
    #
    it 'reports dropped messages' do

      args   = [ :error, :CustomComponent, :custom_code, { :data => :foo } ]
      writer = RSpecTestDroppingSlowWriter.new

      @logger.add( writer )

      # See communicators/pool_spec.rb for rationale.

      expect(writer).to receive(:report).exactly(1).times.with( *args ).and_call_original
      @logger.report( *args )

      loop do
        sleep 0.01
        break if $sync_queue.num_waiting > 0
      end

      # See communicators/pool_spec.rb for rationale. Note the assumption
      # here that the logger is running on a communicator pool, so the queue
      # size there is applicable here. This makes the test potentially fragile.

      limit      = Hoodoo::Communicators::Pool::MAX_SLOW_QUEUE_SIZE
      additional = 10

      # See communicators/pool_spec.rb for rationale.

      1.upto( limit + additional ) do | i |
        @logger.report( *args )
        sleep 2 if i == 1
      end

      # See communicators/pool_spec.rb for rationale.

      expect(writer).to receive(:report).exactly( limit ).times.with( *args ).and_call_original
      $sync_queue << :go!

      # See communicators/pool_spec.rb for rationale.

      @logger.wait()

      # See communicators/pool_spec.rb for rationale; send another report in,
      # provoking first a 'dropped messages' log report.
      #
      # I cannot no matter how hard I try come up with a syntax for RSpec
      # that expects the 'dropped messages' report then '*args'; it just
      # messes up the test conditions ever time, causing timeouts in the
      # processing thread, "writer.count" expectation failures (see end of
      # test) and so-on.

      expect(writer).to receive(:report).once.with(
        :warn,
        'Hoodoo::Logger::SlowCommunicator',
        'dropped.messages',
        "Logging flooded - #{ additional } messages dropped"
      ).and_call_original

      expect(writer).to receive(:report).once.with( *args ).and_call_original

      @logger.report( *args )
      @logger.wait()

      # The writer counts only logged messages - the first 'sync up' message,
      # 'limit' in the queue, 1 reporting the number of dropped messages and
      # 1 that was sent to prompt that dropped messages report.
      #
      # Are you not seeing an expected count? It's possible that the RSpec
      # message receiving expectations earlier were not met. If those fail,
      # the test doesn't halt (theory - RSpec raises exceptions to detect
      # this condition and the pool thread's aggressive exception handler hides
      # all of that?) but the "and-call-original"'s never happen, so the counts
      # are lower than they should be here.

      expect( writer.count ).to eq( 1 + limit + 1 + 1 )
    end
  end
end
