require 'spec_helper'

describe ApiTools::Communicators::Pool do

  before :each do
    @pool = ApiTools::Communicators::Pool.new
  end

  after :each do
    @pool.wait()
  end

  context 'general operation' do

    class TestFastCommunicatorA < ApiTools::Communicators::Fast
      def communicate( obj )
        expectable_hook_fast_a( obj )
      end
    end

    class TestFastCommunicatorB < ApiTools::Communicators::Fast
      def communicate( obj )
        expectable_hook_fast_b( obj )
      end
    end

    class TestFastCommunicatorC < ApiTools::Communicators::Fast
      def communicate( obj )
        raise 'I am broken (Fast C)'
      end
    end

    class TestSlowCommunicatorA < ApiTools::Communicators::Slow
      def communicate( obj )
        expectable_hook_slow_a( obj )
        sleep 0.2 # Deliberate delay to make sure #wait() works;
                  # intermittent failures would imply it doesn't.
      end
    end

    class TestSlowCommunicatorB < ApiTools::Communicators::Slow
      def communicate( obj )
        expectable_hook_slow_b( obj )
      end
    end

    class TestSlowCommunicatorC < ApiTools::Communicators::Slow
      def communicate( obj )
        raise 'I am broken (Slow C)'
      end
    end

    it 'lets me add and remove handlers' do
      c1 = @pool.add( TestFastCommunicatorA.new )
      c2 = @pool.add( TestFastCommunicatorB.new )
      c3 = @pool.add( TestSlowCommunicatorA.new )
      c4 = @pool.add( TestSlowCommunicatorB.new )

      # Should be able to remove them all

      @pool.remove( c1 )
      @pool.remove( c2 )
      @pool.remove( c3 )
      @pool.remove( c4 )

      expect( @pool.instance_variable_get( '@pool' ) ).to be_empty

      # Should be harmess to remove the same thing twice, or remove an instance
      # not in the pool.

      @pool.remove( c1 )
      @pool.remove( TestSlowCommunicatorB.new )

      expect( @pool.instance_variable_get( '@pool' ) ).to be_empty
    end

    it 'calls fast handler A' do
      c1 = @pool.add( TestFastCommunicatorA.new )
      ob = { :foo => :bar }
      expect( c1 ).to receive( :expectable_hook_fast_a ).once.with( ob )
      @pool.communicate( ob )
    end

    it 'calls fast handler A and B' do
      c1 = @pool.add( TestFastCommunicatorA.new )
      c2 = @pool.add( TestFastCommunicatorB.new )
      ob = { :foo => :bar }
      expect( c1 ).to receive( :expectable_hook_fast_a ).once.with( ob )
      expect( c2 ).to receive( :expectable_hook_fast_b ).once.with( ob )
      @pool.communicate( ob )
    end

    it 'calls slow handler A' do
      c1 = @pool.add( TestSlowCommunicatorA.new )
      ob = { :bar => :baz }
      expect( c1 ).to receive( :expectable_hook_slow_a ).once.with( ob )
      @pool.communicate( ob )
    end

    it 'calls slow handler A and B' do
      c1 = @pool.add( TestSlowCommunicatorA.new )
      c2 = @pool.add( TestSlowCommunicatorB.new )
      ob = { :bar => :baz }
      expect( c1 ).to receive( :expectable_hook_slow_a ).once.with( ob )
      expect( c2 ).to receive( :expectable_hook_slow_b ).once.with( ob )
      @pool.communicate( ob )
    end

    it 'calls all handlers' do
      c1 = @pool.add( TestFastCommunicatorA.new )
      c2 = @pool.add( TestFastCommunicatorB.new )
      c3 = @pool.add( TestSlowCommunicatorA.new )
      c4 = @pool.add( TestSlowCommunicatorB.new )
      ob = { :baz => :foo }
      expect( c1 ).to receive( :expectable_hook_fast_a ).once.with( ob )
      expect( c2 ).to receive( :expectable_hook_fast_b ).once.with( ob )
      expect( c3 ).to receive( :expectable_hook_slow_a ).once.with( ob )
      expect( c4 ).to receive( :expectable_hook_slow_b ).once.with( ob )
      @pool.communicate( ob )
    end

    it 'complains about bad additions' do
      expect {
        @pool.add( Object )
      }.to raise_exception( RuntimeError )
    end

    it 'complains about bad removals' do
      expect {
        @pool.remove( Object )
      }.to raise_exception( RuntimeError )
    end

    it 'ignores exceptions in reporters' do
      c1 = @pool.add( TestFastCommunicatorC.new ) # Add "exception raisers first
      c2 = @pool.add( TestSlowCommunicatorC.new )
      c3 = @pool.add( TestFastCommunicatorA.new ) # Then these after, which should still be called
      c4 = @pool.add( TestSlowCommunicatorA.new )
      ob = { :foo => :bar }
      expect( c3 ).to receive( :expectable_hook_fast_a ).once.with( ob )
      expect( c4 ).to receive( :expectable_hook_slow_a ).once.with( ob )
      @pool.communicate( ob )
    end

    it 'ignores exceptions in exception handler' do
      c1 = @pool.add( TestFastCommunicatorC.new ) # Add "exception raisers first
      c2 = @pool.add( TestSlowCommunicatorC.new )
      c3 = @pool.add( TestFastCommunicatorA.new ) # Then these after, which should still be called
      c4 = @pool.add( TestSlowCommunicatorA.new )
      ob = { :foo => :bar }

      # Expect a debug report on 'stderr'; force the first one to fail, let
      # the next one through quietly. Everything should be called as expected
      # even though 'stderr' failed.

      expect( $stderr ).to receive( :puts ).once do
        raise 'stderr failure'
      end
      expect( $stderr ).to receive( :puts ).once.and_call_original
      expect( c3 ).to receive( :expectable_hook_fast_a ).once.with( ob )
      expect( c4 ).to receive( :expectable_hook_slow_a ).once.with( ob )
      @pool.communicate( ob )
    end
  end

  context 'message dropping' do
    before :all do
      $sync_queue = Queue.new
    end

    class TestSlowCommunicatorDrops < ApiTools::Communicators::Slow
      def initialize
        @count = 0
      end

      # This consumes one message then tries to pop a queue item, forcing it
      # to wait for the test code to push. This lets us control completely
      # consistently thread execution, guaranteeing no further processing of
      # messages until we want to let it run.
      #
      def communicate( obj )
        $sync_queue.pop if @count == 0
        @count += 1
      end

      def dropped( number )
        @count += number
      end

      def count
        @count
      end
    end

    # Potentially fragile, but on all except the very slowest machines, the
    # sleep times should give plenty of CPU cycles up for things to finish
    # in the implied order.

    it 'reports dropped messages' do
      c = @pool.add( TestSlowCommunicatorDrops.new )
      o = { :foo => :bar }

      # Send one message, causing the communicator to process it and then wait
      # on the queue. Wait for the pool to drain so we know it has done this.

      expect(c).to receive(:communicate).exactly( 1 ).times.and_call_original

      @pool.communicate( o )
      @pool.wait( communicator: c )

      # Now send a full queue of messages, plus some additional ones.

      limit = ApiTools::Communicators::Pool::MAX_SLOW_QUEUE_SIZE
      additional = 10

      1.upto( limit + additional ) do |i|
        @pool.communicate( o )
      end

      # The slow communicator is still waiting on our sync queue after that
      # first message. Let it run; we thus expect it to process a full queue
      # size of messages, but the 'additional' ones will have been dropped.

      expect(c).to receive(:communicate).exactly( limit ).times.and_call_original
      $sync_queue.push( :anything )

      # Wait for it to finish processing again.

      @pool.wait( communicator: c )

      # Now send one final message. This will prompt the 'dropped' call first,
      # saying "<x> were dropped between the last communication and this one",
      # then send in the recent message.

      expect(c).to receive(:communicate).exactly( 1 ).times.and_call_original
      expect(c).to receive(:dropped).exactly( 1 ).times.with( additional ).and_call_original

      @pool.communicate( o )

      # Finally, wait for all processing to be done by the communicator before
      # verifying that it saw the right number of messages or drops.

      @pool.wait( communicator: c )

      expect( c.count ).to eq( 1 + limit + additional + 1 )
    end
  end

  context 'waiting, termination and timeouts' do
    class TestSlowCommunicatorSleeps < ApiTools::Communicators::Slow
      def communicate( obj )
        sleep( obj )
      end
    end

    before :each do
      @pool = ApiTools::Communicators::Pool.new
    end

    it 'times out waiting' do
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )

      expect( @pool.group.list.size ).to eq( 3 )

      # Sleep each for 2 seconds, wait with a timeout of 0.02 seconds,
      # expect the test to take less than 1 second overall. Non-timeout
      # waiting is already tested elsewhere.

      now = Time.now

      @pool.communicate( 2 )
      @pool.wait( per_instance_timeout: 0.02 )

      expect( Time.now - now ).to be < 1
    end

    it 'times out termination' do
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )

      expect( @pool.group.list.size ).to eq( 3 )

      # Sleep each for 9999 seconds, terminate with a 0.02 second timeout.
      # Expect to exit the termination early, with the pool still intact
      # (since all threads should've timed out).

      now = Time.now

      @pool.communicate( 9999 )
      @pool.wait # Make sure all communicators received message and are sleeping
      @pool.terminate( per_instance_timeout: 0.02 )

      expect( Time.now - now ).to be < 1
      expect( @pool.group.list.size ).to eq( 3 )
    end

    it 'terminates properly without timeout' do
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )

      expect( @pool.group.list.size ).to eq( 3 )

      # Sleep each communicator for just 0.02 seconds and terminate without
      # timeouts. Expect it to all succeed, with nothing left in the pool.

      @pool.communicate( 0.02 )
      @pool.terminate()

      expect( @pool.group.list.size ).to eq( 0 )
    end
  end
end
