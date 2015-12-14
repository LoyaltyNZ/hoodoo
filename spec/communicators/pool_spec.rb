require 'spec_helper'

describe Hoodoo::Communicators::Pool do

  before :each do
    @pool = Hoodoo::Communicators::Pool.new
  end

  context 'general operation' do
    after :each do
      @pool.wait()
    end

    class TestFastCommunicatorA < Hoodoo::Communicators::Fast
      def communicate( obj )
        expectable_hook_fast_a( obj )
      end
    end

    class TestFastCommunicatorB < Hoodoo::Communicators::Fast
      def communicate( obj )
        expectable_hook_fast_b( obj )
      end
    end

    class TestFastCommunicatorC < Hoodoo::Communicators::Fast
      def communicate( obj )
        raise 'I am broken (Fast C)'
      end
    end

    class TestSlowCommunicatorA < Hoodoo::Communicators::Slow
      def communicate( obj )
        expectable_hook_slow_a( obj )
        sleep 0.2 # Deliberate delay to make sure #wait() works;
                  # intermittent failures would imply it doesn't.
      end
    end

    class TestSlowCommunicatorB < Hoodoo::Communicators::Slow
      def communicate( obj )
        expectable_hook_slow_b( obj )
      end
    end

    class TestSlowCommunicatorC < Hoodoo::Communicators::Slow
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
      c1 = @pool.add( TestFastCommunicatorC.new ) # Add exception raisers first
      c2 = @pool.add( TestSlowCommunicatorC.new )
      c3 = @pool.add( TestFastCommunicatorA.new ) # Then these after, which should still be called
      c4 = @pool.add( TestSlowCommunicatorA.new )
      ob = { :foo => :bar }
      expect( c3 ).to receive( :expectable_hook_fast_a ).once.with( ob )
      expect( c4 ).to receive( :expectable_hook_slow_a ).once.with( ob )
      @pool.communicate( ob )
    end

    it 'ignores exceptions in exception handler' do
      c1 = @pool.add( TestFastCommunicatorC.new ) # Add exception raisers first
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
    before :each do

      # This sync queue is pushed from the running test and popped from the
      # communicators inside their message handler, so that we can force the
      # communicators to halt "mid-message" by not pushing until we're ready.

      $sync_queue = Queue.new

    end

    class TestSlowCommunicatorDrops < Hoodoo::Communicators::Slow
      def initialize
        @count = 0
      end

      attr_reader :count

      def communicate( obj )
        $sync_queue.pop if @count == 0
        @count += 1
      end

      def dropped( number )
        @count += number
      end
    end

    it 'reports dropped messages' do
      c = @pool.add( TestSlowCommunicatorDrops.new )
      o = { :foo => :bar }

      # Send a message. The only way we have to sync up in this test here
      # is to busy poll our sync queue until we see the communicator thread
      # waiting on it. That means it pulled the message of its work queue and
      # is now blocked in the message handler until we push to the sync queue.

      expect(c).to receive(:communicate).once.with( o ).and_call_original
      @pool.communicate( o )

      loop do
        sleep 0.01
        break if $sync_queue.num_waiting > 0
      end

      # Now send a full queue of messages. That'll send "limit", none of which
      # will be processed yet, then queue "additional".

      limit      = Hoodoo::Communicators::Pool::MAX_SLOW_QUEUE_SIZE
      additional = 10

      1.upto( limit + additional ) do | i |
        @pool.communicate( o )
        sleep 1 if i == 1
      end

      # The communicator's still waiting on our sync queue. We expect it to get
      # the "limit" queued calls; let it start processing by pushing something
      # to the sync queue.

      expect(c).to receive(:communicate).exactly( limit ).times.with( o ).and_call_original
      $sync_queue << :go!

      # Wait for the communicator to finish processing. Implicit test -
      # variant of "wait" that takes a specific communicator.

      @pool.wait( communicator: c )

      # Now send one final message. This will prompt the 'dropped' call first,
      # saying "<x> were dropped between the last communication and this one",
      # then send in the recent message.

      expect(c).to receive(:dropped).once.with( additional ).and_call_original
      expect(c).to receive(:communicate).once.with( o ).and_call_original

      @pool.communicate( o )
      @pool.wait( communicator: c )

      # The 'count' variable in the communicator records the number of
      # messages it received, or that were dropped, adding them all up.
      # There was the first 'sync up' message, 'limit' messages in the
      # queue, 'additional' counted via the "dropped" call and one more
      # message that provoked the "dropped" call.

      expect( c.count ).to eq( 1 + limit + additional + 1 )
    end
  end

  context 'waiting, termination and timeouts' do

    before :each do

      # This sync queue gets pushed from the communicators before they sleep,
      # and popped by the running test so it knows the communicator threads
      # received a message and are about to sleep for a while within their
      # message handler.
      #
      $sync_queue = Queue.new

    end

    class TestSlowCommunicatorSleeps < Hoodoo::Communicators::Slow
      def communicate( obj )
        $sync_queue << :sync
        sleep( obj )
      end
    end

    it 'times out waiting' do
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )

      expect( @pool.group.list.size ).to eq( 3 )

      # Sleep each for 1 second, wait with a timeout of 0.02 seconds, expect
      # the test to take less than 0.5 seconds overall. Non-timeout waiting
      # is already tested elsewhere.

      now = Time.now

      @pool.communicate( 1 )
      1.upto( 3 ) { $sync_queue.pop() } # Make sure all threads got the message

      @pool.wait( per_instance_timeout: 0.02 )

      expect( Time.now - now ).to be < 0.5
    end

    it 'times out termination' do
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )

      expect( @pool.group.list.size ).to eq( 3 )

      # Sleep each for 5 seconds, terminate with a 0.02 second timeout.
      # Expect to exit the termination early, with the pool still intact
      # (since all threads should've timed out).
      #
      # The test comms threads will hang around in the runtime for a while
      # then expire naturally or, if the test suite exits first, get killed
      # off along with the running Ruby process.

      now = Time.now

      @pool.communicate( 5 )
      1.upto( 3 ) { $sync_queue.pop() } # Make sure all threads got the message
      @pool.terminate( per_instance_timeout: 0.02 ) # Now we know they're all asleep, try a timed-out termination.

      expect( Time.now - now ).to be < 1
      expect( @pool.group.list.size ).to eq( 3 ) # All threads timed out
    end

    it 'terminates properly without timeout' do
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )
      c = @pool.add( TestSlowCommunicatorSleeps.new )

      expect( @pool.group.list.size ).to eq( 3 )

      # Sleep each communicator for just 0.02 seconds and terminate without
      # timeouts. Expect it to all succeed, with nothing left in the pool.

      now = Time.now

      @pool.communicate( 0.02 )
      1.upto( 3 ) { $sync_queue.pop() } # Make sure all threads got the message
      @pool.terminate()

      expect( Time.now - now ).to be < 1
      expect( @pool.group.list.size ).to eq( 0 ) # All threads exited
    end
  end
end
