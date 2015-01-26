########################################################################
# File::    pool.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A pool of communication-orientated objects which are either
#           fast and operate synchronously, or are slow and are called
#           asynchronously via a Ruby Thread.
# ----------------------------------------------------------------------
#           15-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Communicators
    class Pool

      # Hoodoo::Communicators::Slow subclass communicators are called in
      # their own Threads via a processing Queue. There is the potential for
      # a flood of communications to cause the queue to back up considerably,
      # so a maximum number of messages is defined. If the queue size is
      # _equal to or greater_ than this amount when a message arrives, it
      # will be dropped and a 'dropped message' count incremented.
      #
      MAX_SLOW_QUEUE_SIZE = 50

      # When asking slow communicator threads to exit, a timeout must be used
      # in case the thread doesn't seem to be responsive. This is the timeout
      # value in seconds - it can take a floating point or integer value.
      #
      THREAD_EXIT_TIMEOUT = 5

      # Analogous to ::THREAD_WAIT_TIMEOUT but used when waiting for a
      # processing Thread to drain its Queue, without asking it to exit.
      #
      THREAD_WAIT_TIMEOUT = 5

      # Retrieve the ThreadGroup instance managing the collection of slow
      # communicator threads. This is mostly used for testing purposes and
      # has little general purpose utility.
      #
      attr_accessor :group

      # Create a new pool of communicators - instances of subclasses of
      # Hoodoo::Communicators::Fast or Hoodoo::Communicators::Slow,
      # are added with #add and called with #communicate.
      #
      def initialize
        @pool  = {}
        @group = ThreadGroup.new
      end

      # Add a communicator instance to the pool. Future calls to #communicate
      # will call the same-named method in that instance.
      #
      # Subclasses of Hoodoo::Communicators::Slow are called within a
      # processing Thread. Subclasses of Hoodoo::Communicators::Fast are
      # called inline. The instances are called in the order of addition, but
      # since each slow communicator runs in its own Thread, the execution
      # order is indeterminate for such instances.
      #
      # If a slow communicator's inbound message queue length matches or
      # exceeds ::MAX_SLOW_QUEUE_SIZE, messages for that specific communicator
      # will start being dropped until the communicator clears the backlog and
      # at last one space opens on the queue. Slow communicators can detect
      # when this has happened by implementing
      # Hoodoo::Communicators::Slow#dropped in the subclass.
      #
      # If you pass the same instance more than once, the subsequent calls are
      # ignored. You can add many instances of the same class if that's useful
      # for any reason.
      #
      # Returns the passed-in communicator instance parameter, for convenience.
      #
      # +communicator+:: Instance is to be added to the pool. Must be
      #                  either an Hoodoo::Communicators::Fast or
      #                  Hoodoo::Communicators::Slow subclass instance.
      #
      def add( communicator )
        unless ( communicator.class < Hoodoo::Communicators::Fast ||
                 communicator.class < Hoodoo::Communicators::Slow )
          raise "Hoodoo::Communicators::Pool\#add must be called with an instance of a subclass of Hoodoo::Communicators::Fast or Hoodoo::Communicators::Slow only"
        end

        return if @pool.has_key?( communicator )

        if communicator.is_a?( Hoodoo::Communicators::Fast )
          add_fast_communicator( communicator )
        else
          add_slow_communicator( communicator )
        end

        return communicator
      end

      # Remove a communicator previously added by #add. See that for details.
      #
      # It is harmless to try and remove communicator instances more than once
      # or to try to remove something that was never added in the first place;
      # the call simply has no side effects.
      #
      # If removing a slow communicator, its thread will be terminated with
      # default timeout value of ::THREAD_EXIT_TIMEOUT seconds. For this
      # reason, removing a slow communicator may take a long time.
      #
      # Returns the passed-in communicator instance parameter, for convenience.
      #
      # +communicator+:: Instance is to be removed from the pool. Must be
      #                  either an Hoodoo::Communicators::Fast or
      #                  Hoodoo::Communicators::Slow subclass instance.
      #
      def remove( communicator )
        unless ( communicator.class < Hoodoo::Communicators::Fast ||
                 communicator.class < Hoodoo::Communicators::Slow )
          raise "Hoodoo::Communicators::Pool\#remove must be called with an instance of a subclass of Hoodoo::Communicators::Fast or Hoodoo::Communicators::Slow only"
        end

        return unless @pool.has_key?( communicator )

        if communicator.is_a?( Hoodoo::Communicators::Fast )
          remove_fast_communicator( communicator )
        else
          remove_slow_communicator( communicator )
        end

        return communicator
      end

      # Call the #communicate method on each communicator instance added via
      # #add. Each instance is called in the same order as corresponding
      # calls are made to the pool. _Across_ instances, fast communicators are
      # called in the order they were added to the pool, but since each slow
      # communicator runs in its own Thread, execution order is indeterminate.
      #
      # +object+:: Parameter passed to the communicator subclass instance
      #            #communicate methods.
      #
      def communicate( object )
        @pool.each do | communicator, item |

          if item.has_key?( :fast )
            begin
              communicator.communicate( object )
            rescue => exception
              handle_exception( exception, communicator )
            end

          else
            data       = item[ :slow       ]
            thread     = data[ :thread     ]
            work_queue = data[ :work_queue ]

            # This is inaccurate if one or more "dropped messages" reports are
            # on the queue, but since some communicators might report them in
            # the same way as other messages, it's not necessarily incorrect
            # either.
            #
            if work_queue.size < MAX_SLOW_QUEUE_SIZE
              dropped = thread[ :dropped_messages ]

              if dropped > 0
                thread[ :dropped_messages ] = 0

                # Opposite of comment above on MAX_SLOW_QUEUE_SIZE check...
                # Yes, this takes up a queue entry and the payload addition
                # afterwards might take it one above max size, but that's OK
                # since this is just a "dropped messages" report and though
                # some communicators might deal with them slowly, others may
                # just ignore them.
                #
                work_queue << QueueEntry.new( dropped: dropped )
              end

              work_queue << QueueEntry.new( payload: object )

            else
              thread[ :dropped_messages ] += 1

            end
          end

        end
      end

      # This method is only useful if there are any
      # Hoodoo::Communicators::Slow subclass instances in the communication
      # pool. Each instance is called via a worker Thread; this method waits
      # for each communicator to drain its queue before returning. This is
      # useful if you have a requirement to wait for all communications to
      # finish on all threads, presumably for wider synchronisation reasons.
      #
      # Since fast communicators are called synchronously there is never any
      # need to wait for them, so this call ignores such pool entries.
      #
      # The following *named* parameters are supported:
      #
      # +per_instance_timeout+:: Timeout for _each_ slow communicator Thread
      #                          in seconds. Optional. Default is the value
      #                          in ::THREAD_WAIT_TIMEOUT.
      #
      # +communicator+::         If you want to wait for specific instance only
      #                          (see #add), pass it here. If the instance is a
      #                          fast communicator, or any object not added to
      #                          the pool, then there is no error raised. The
      #                          method simply returns immediately.
      #
      def wait( per_instance_timeout: THREAD_WAIT_TIMEOUT,
                communicator:         nil )

        if communicator.nil?
          @pool.each do | communicator, item |
            next unless item.has_key?( :slow )
            data = item[ :slow ]

            wait_for(
              work_queue: data[ :work_queue ],
              sync_queue: data[ :sync_queue ],
              timeout:    per_instance_timeout
            )
          end

        else
          return unless @pool.has_key?( communicator )
          item = @pool[ communicator ]

          return unless item.has_key?( :slow )
          data = item[ :slow ]

          wait_for(
            work_queue: data[ :work_queue ],
            sync_queue: data[ :sync_queue ],
            timeout:    per_instance_timeout
          )

        end
      end

      # The communication pool is "emptied" by this call, going back to a
      # clean state as if just initialised. New workers can be added via #add
      # and then called via #communicate if you so wish.
      #
      # Hoodoo::Communciators::Fast subclass instances are removed
      # immediately without complications.
      #
      # Hoodoo::Communicators::Slow subclass instances in the communication
      # pool are called via a worker Thread; this method shuts down all such
      # worker Threads, clearing their work queues and asking each one to exit
      # (politely). There is no mechanism (other than overall Ruby process
      # exit) available to shut down the Threads by force, so some Threads may
      # not respond and time out.
      #
      # When this method exits, all workers will have either exited or timed
      # out and possibly still be running, but are considered too slow or dead.
      # No further communications are made to them.
      #
      # The following *named* parameters are supported:
      #
      # +per_instance_timeout+:: Timeout for _each_ slow communicator Thread
      #                          in seconds. Optional. Default is the value
      #                          in ::THREAD_EXIT_TIMEOUT. For example,
      #                          with three slow communicators in the pool
      #                          and all three reached a 5 second timeout,
      #                          the termination method would not return for
      #                          15 seconds (3 * 5 seconds full timeout).
      #
      def terminate( per_instance_timeout: THREAD_EXIT_TIMEOUT )
        loop do
          klass, item = @pool.shift() # Hash#shift -> remove a key/value pair.
          break if klass.nil?

          next unless item.has_key?( :slow )
          data = item[ :slow ]

          request_termination_for(
            thread:     data[ :thread     ],
            work_queue: data[ :work_queue ],
            timeout:    per_instance_timeout
          )
        end
      end

    private

      # Add a fast communicator to the pool. Requires no thread or queue.
      #
      # Trusted internal interface - pass the correct subclass and don't pass
      # it more than once unless #terminate has cleared the pool beforehand.
      #
      # +communicator+:: The Hoodoo::Communicators::Fast subclass instance
      #                  to add to the pool.
      #
      def add_fast_communicator( communicator )
        @pool[ communicator ] = { :fast => true }
      end

      # Remove a fast communicator from the pool. See #add_fast_communicator.
      #
      # +communicator+:: The Hoodoo::Communicators::Fast subclass instance
      #                  to remove from the pool.
      #
      def remove_fast_communicator( communicator )
        @pool.delete( communicator )
      end

      # Add a slow communicator to the pool. Requires a thread and queue.
      #
      # Trusted internal interface - pass the correct subclass and don't pass
      # it more than once unless #terminate has cleared the pool beforehand.
      #
      # +communicator+:: The Hoodoo::Communicators::Slow subclass instance
      #                  to add to the pool.
      #
      def add_slow_communicator( communicator )

        work_queue = Queue.new
        sync_queue = QueueWithTimeout.new

        # Start (and keep a reference to) a thread that just loops around
        # processing queue messages until asked to exit.

        thread = Thread.new do

          # Outer infinite loop restarts queue processing if exceptions occur.
          #
          loop do

            # Exception handler block.
            #
            begin

              # Inner infinite loop processes queue objects until asked to exit
              # via a +nil+ queue entry.
              #
              loop do
                entry = work_queue.shift() # ".shift" => FIFO, ".pop" would be LIFO

                if entry.terminate?
                  Thread.exit
                elsif entry.sync?
                  sync_queue << :sync
                elsif entry.dropped?
                  communicator.dropped( entry.dropped )
                else
                  communicator.communicate( entry.payload )
                end
              end

            rescue => exception
              handle_exception( exception, communicator )

            end
          end
        end

        thread[ :dropped_messages ] = 0

        @group.add( thread )
        @pool[ communicator ] = {
          :slow => {
            :thread     => thread,
            :work_queue => work_queue,
            :sync_queue => sync_queue,
          }
        }
      end

      # Remove a slow communicator from the pool. See #add_slow_communicator.
      #
      # May take a while to return, as it must request thread shutdown via
      # #request_termination_for (and uses the default timeout for that).
      #
      # +communicator+:: The Hoodoo::Communicators::Slow subclass instance
      #                  to remove from the pool.
      #
      def remove_slow_communicator( communicator )
        item = @pool[ communicator ]
        data = item[ :slow ]

        request_termination_for(
          thread:     data[ :thread     ],
          work_queue: data[ :work_queue ]
        )

        @pool.delete( communicator )
      end

      # Ask a slow communicator Thread to exit. Existing work on any Queues
      # is cleared first, so only the current in-process message for a given
      # communicator has to finish prior to exit.
      #
      # *Named* parameters are:
      #
      # +:thread+::     Mandatory. Worker Thread for the communicator.
      # +:work_queue+:: Mandatory. Queue used to send work to the Thread.
      # +timeout+::     Optional timeout in seconds - default is
      #                 THREAD_EXIT_TIMEOUT.
      #
      # The method returns if the timeout threshold is exceeded, without
      # raising any exceptions.
      #
      def request_termination_for( thread:, work_queue:, timeout: THREAD_EXIT_TIMEOUT )
        work_queue.clear()
        work_queue << QueueEntry.new( terminate: true )

        thread.join( timeout )
      end

      # Wait for a slow communicator Thread to empty its work Queue. *Named*
      # parameters are:
      #
      # +:work_queue+:: Mandatory. Queue used to send work to the Thread.
      # +:sync_queue+:: Mandatory. Queue used by that Thread to send back a
      #                 sync notification to the pool.
      # +timeout+::     Optional timeout in seconds - default is
      #                 THREAD_WAIT_TIMEOUT.
      #
      # The method returns if the timeout threshold is exceeded, without
      # raising any exceptions.
      #
      def wait_for( work_queue:, sync_queue:, timeout: THREAD_WAIT_TIMEOUT )

        # Push a 'sync' entry onto the work Queue. Once the worker Thread gets
        # through other Queue items and reaches this entry, it'll respond
        # by pushing an item onto its sync Queue.

        work_queue << QueueEntry.new( sync: true )

        # Wait on the sync Queue for the worker Thread to send the requested
        # message indicating that we're in sync.

        begin
          sync_queue.shift( timeout )

        rescue ThreadError
          # Do nothing

        end
      end

      # Intended for cases where a communicator raised an exception - print
      # details to $stderr. This is all we can do; the logging engine runs
      # through the communications pool so attempting to log an exception
      # might cause an exception that we then attempt to log - and so-on.
      #
      # +exception+::    Exception (or Exception subclass) instance to print.
      # +communicator+:: Communicator instance that raised the exception.
      #
      def handle_exception( exception, communicator )
        begin
          report = "Slow communicator class #{ communicator.class.name } raised exception '#{ exception }': #{ exception.backtrace }"
          $stderr.puts( report )

        rescue
          # If the above fails then everything else is probably about to
          # collapse, but optimistically try to ignore the error and keep
          # the wider processing code alive.

        end
      end

      # Internal implementation detail of Hoodoo::Communicators::Pool.
      #
      # Since pool clients can say "wait until (one or all) workers have
      # processed their Queue contents", we need to have some way of seeing
      # when all work is done. The clean way to do it is to push 'sync now'
      # messages onto the communicator Threads work Queues, so that as they
      # work through the Queue they'll eventually reach that message. They then
      # push a message onto a sync Queue for that worker. Meanwhile the waiting
      # pool does (e.g.) a +pop+ on the sync Queue, which means it blocks until
      # the workers say they've finished. No busy waiting, Ruby gets to make
      # its best guess at scheduling, etc.; all good.
      #
      # The catch? You can't use +Timeout::timeout...do...+ around a Queue
      # +pop+. It just doesn't work. It's a strange omission and requires code
      # gymnastics to work around.
      #
      # Enter QueueWithTimeout, from:
      #
      #   http://spin.atomicobject.com/2014/07/07/ruby-queue-pop-timeout/
      #
      class QueueWithTimeout

        # Create a new instance.
        #
        def initialize
          @mutex    = Mutex.new
          @queue    = []
          @recieved = ConditionVariable.new
        end

        # Push a new entry to the end of the queue.
        #
        # +entry+:: Entry to put onto the end of the queue.
        #
        def <<( entry )
          @mutex.synchronize do
            @queue << entry
            @recieved.signal
          end
        end

        # Take an entry from the front of the queue (FIFO) with optional
        # timeout if the queue is empty.
        #
        # +timeout+:: Timeout (in seconds, Integer or Float) to wait for an
        #             item to appear on the queue, if the queue is empty. If
        #             +nil+, there is no timeout (waits indefinitely).
        #             Optional; default is +nil+.
        #
        # If given a non-+nil+ timeout value and the timeout expires, raises
        # a ThreadError exception (just as non-blocking Ruby Queue#pop would).
        #
        def shift( timeout = nil )
          @mutex.synchronize do
            if @queue.empty?
              @recieved.wait( @mutex, timeout ) if timeout != 0
              raise( ThreadError, 'queue empty' ) if @queue.empty?
            end

            @queue.shift
          end
        end
      end

      # Internal implementation detail of Hoodoo::Communicators::Pool which
      # is placed on a Ruby Queue and used as part of thread processing for
      # slow communicators.
      #
      class QueueEntry

        # If +true+, the processing Thread should exit. See also #terminate?.
        #
        attr_accessor :terminate

        # If +true+, the processing Thread should push one item with any
        # payload onto its sync Queue. See also #sync?
        #
        attr_accessor :sync

        # If not +nil+ or zero, the number of dropped messages that should be
        # send to the slow communicator subclass's #dropped method. See also
        # #dropped?
        #
        attr_accessor :dropped

        # If the entry represents neither a termination request nor a dropped
        # message count (see #terminate? and #dropped?), the payload to send to
        # the slow communicator subclass's #communicate method.
        #
        attr_accessor :payload

        # Create a new instance, ready to be added to the Queue.
        #
        # *ONLY* *USE* *ONE* of the named parameters:
        #
        # +payload+::   A parameter to send to #communicate in the communicator.
        # +dropped+::   The integer to send to #dropped in the communicator.
        # +terminate+:: Set to +true+ to exit the processing thread when the
        #               entry is read from the Queue.
        # +sync+::      Set to +true+ to push a message onto the sync Queue.
        #
        def initialize( payload: nil, dropped: nil, terminate: false, sync: false )
          @payload   = payload
          @dropped   = dropped
          @terminate = terminate
          @sync      = sync
        end

        # Returns +true+ if encountering this queue entry should terminate the
        # processing thread, else +false+ (see #dropped? then #payload).
        #
        def terminate?
          @terminate == true
        end

        # Returns +true+ if this queue entry represents a request to push a
        # message onto the processing Thread's sync Queue.
        #
        def sync?
          @sync == true
        end

        # Returns +true+ if this queue entry represents a dropped message count
        # (see #dropped), else +false (see #terminate? then #payload).
        #
        def dropped?
          @dropped != nil && @dropped > 0
        end
      end
    end
  end
end
