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

module ApiTools
  module Communicators
    class Pool

      # ApiTools::Communicators::Slow subclass communicators are called in
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
      # ApiTools::Communicators::Fast or ApiTools::Communicators::Slow,
      # are added with #add and called with #communicate.
      #
      def initialize
        @pool  = {}
        @group = ThreadGroup.new
      end

      # Add a communicator instance to the pool. Future calls to #communicate
      # will call the same-named method in that instance.
      #
      # Subclasses of ApiTools::Communicators::Slow are called within a
      # processing Thread. Subclasses of ApiTools::Communicators::Fast are
      # called inline. The instances are called in the order of addition, but
      # since each slow communicator runs in its own Thread, the execution
      # order is indeterminate for such instances.
      #
      # If a slow communicator's inbound message queue length matches or
      # exceeds ::MAX_SLOW_QUEUE_SIZE, messages for that specific communicator
      # will start being dropped until the communicator clears the backlog and
      # at last one space opens on the queue. Slow communicators can detect
      # when this has happened by implementing
      # ApiTools::Communicators::Slow#dropped in the subclass.
      #
      # If you pass the same instance more than once, the subsequent calls are
      # ignored. You can add many instances of the same class if that's useful
      # for any reason.
      #
      # Returns the passed-in communicator instance parameter, for convenience.
      #
      # +communicator+:: Instance is to be added to the pool. Must be
      #                  either an ApiTools::Communicators::Fast or
      #                  ApiTools::Communicators::Slow subclass instance.
      #
      def add( communicator )
        unless ( communicator.class < ApiTools::Communicators::Fast ||
                 communicator.class < ApiTools::Communicators::Slow )
          raise "ApiTools::Communicators::Pool\#add must be called with an instance of a subclass of ApiTools::Communicators::Fast or ApiTools::Communicators::Slow only"
        end

        return if @pool.has_key?( communicator )

        if communicator.is_a?( ApiTools::Communicators::Fast )
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
      #                  either an ApiTools::Communicators::Fast or
      #                  ApiTools::Communicators::Slow subclass instance.
      #
      def remove( communicator )
        unless ( communicator.class < ApiTools::Communicators::Fast ||
                 communicator.class < ApiTools::Communicators::Slow )
          raise "ApiTools::Communicators::Pool\#remove must be called with an instance of a subclass of ApiTools::Communicators::Fast or ApiTools::Communicators::Slow only"
        end

        return unless @pool.has_key?( communicator )

        if communicator.is_a?( ApiTools::Communicators::Fast )
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
              print_exception( exception, communicator )
            end

          else
            slow   = item[ :slow ]
            queue  = slow[ :queue  ]
            thread = slow[ :thread ]

            # This is inaccurate if one or more "dropped messages" reports are
            # on the queue, but since some communicators might report them in
            # the same way as other messages, it's not necessarily incorrect
            # either.
            #
            if queue.size < MAX_SLOW_QUEUE_SIZE
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
                queue << QueueEntry.new( dropped: dropped )
              end

              queue << QueueEntry.new( payload: object )

            else
              thread[ :dropped_messages ] += 1

            end
          end

        end
      end

      # This method is only useful if there are any
      # ApiTools::Communicators::Slow subclass instances in the communication
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

            slow   = item[ :slow ]
            queue  = slow[ :queue  ]
            thread = slow[ :thread ]

            wait_for( queue, thread, per_instance_timeout )
          end

        else
          info = @pool[ communicator ]
          return if info.nil?

          slow = info[ :slow ]
          return if slow.nil?

          queue  = slow[ :queue  ]
          thread = slow[ :thread ]

          wait_for( queue, thread, per_instance_timeout )

        end
      end

      # This method is only useful if there are any
      # ApiTools::Communicators::Slow subclass instances in the communication
      # pool. Each instance is called via a worker Thread; this method shuts
      # down all such worker Threads, clearing their work queues and asking
      # each one to exit (politely). There is no mechanism (other than overall
      # Ruby process exit) available to shut down the Threads by force.
      #
      # When this method exits, all workers will have either exited or timed
      # out and possibly still be running, but are considered too slow or dead.
      # No further communications are made to them.
      #
      # This communication pool is "emptied" by this call, going back to a
      # clean state as if just initialised. New workers can be added via #add
      # and then called via #communicate if you so wish.
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
          klass, item = @pool.shift()
          break if klass.nil?
          next if item.has_key?( :fast )

          slow   = item[ :slow ]
          queue  = slow[ :queue  ]
          thread = slow[ :thread ]

          request_termination_for( queue, thread, per_instance_timeout )
        end
      end

    private

      # Add a fast communicator to the pool. Requires no thread or queue.
      #
      # Trusted internal interface - pass the correct subclass and don't pass
      # it more than once unless #terminate has cleared the pool beforehand.
      #
      # +communicator+:: The ApiTools::Communicators::Fast subclass instance
      #                  to add to the pool.
      #
      def add_fast_communicator( communicator )
        @pool[ communicator ] = { :fast => true }
      end

      # Remove a fast communicator from the pool. See #add_fast_communicator.
      #
      # +communicator+:: The ApiTools::Communicators::Fast subclass instance
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
      # +communicator+:: The ApiTools::Communicators::Slow subclass instance
      #                  to add to the pool.
      #
      def add_slow_communicator( communicator )

        queue = Queue.new

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
                entry = queue.pop()

                if entry.terminate?
                  Thread.exit
                elsif entry.dropped?
                  communicator.dropped( entry.dropped )
                else
                  communicator.communicate( entry.payload )
                end
              end

            rescue => exception
              print_exception( exception, communicator )

            end
          end
        end

        thread[ :dropped_messages ] = 0

        @group.add( thread )
        @pool[ communicator ] = {
          :slow => {
            :queue  => queue,
            :thread => thread
          }
        }
      end

      # Remove a slow communicator from the pool. See #add_slow_communicator.
      #
      # May take a while to return, as it must request thread shutdown via
      # #request_termination_for (and uses the default timeout for that).
      #
      # +communicator+:: The ApiTools::Communicators::Slow subclass instance
      #                  to remove from the pool.
      #
      def remove_slow_communicator( communicator )
        info   = @pool[ communicator ]
        slow   = info[ :slow ]
        queue  = slow[ :queue  ]
        thread = slow[ :thread ]

        request_termination_for( queue, thread )

        @pool.delete( communicator )
      end

      # Ask a slow communicator thread to exit.
      #
      # +queue+::   Queue to use for thread communication.
      # +thread+::  Thread listening to the Queue.
      # +timeout+:: Timeout in seconds - default is THREAD_EXIT_TIMEOUT.
      #
      # The method returns if the timeout threshold is exceeded, without
      # raising any exceptions.
      #
      def request_termination_for( queue, thread, timeout = THREAD_EXIT_TIMEOUT )
        queue.clear()
        queue << QueueEntry.new( terminate: true )
        thread.join( timeout )
      end

      # Wait for a slow communicator thread to empty its queue.
      #
      # +queue+::   Queue to use for thread communication.
      # +thread+::  Thread listening to the Queue.
      # +timeout+:: Timeout in seconds - default is THREAD_WAIT_TIMEOUT.
      #
      # The method returns if the timeout threshold is exceeded, without
      # raising any exceptions.
      #
      def wait_for( queue, thread, timeout = THREAD_WAIT_TIMEOUT )
        begin
          Timeout::timeout( timeout ) do
            loop do
              break if queue.size == 0
              sleep 0.1
            end
          end

        rescue Timeout::Error
          # Do nothing

        end
      end

      # Intended for cases where a communicator raised an exception - print
      # details to $stderr.
      #
      # +exception+::    Exception (or Exception subclass) instance to print.
      # +communicator+:: Communicator instance that raised the exception.
      #
      def print_exception( exception, communicator )
        begin
          $stderr.puts( "Slow communicator class #{ communicator.class.name } raised exception #{ exception }: #{ exception.backtrace }" )
        rescue
          # If the above fails then everything else is probably about to
          # collapse, but optimistically try to ignore the error and keep
          # the wider processing code alive.
        end
      end

      # Internal implementation detail of ApiTools::Communicators::Pool which
      # is placed on a Ruby Queue and used as part of thread processing for
      # slow communicators.
      #
      class QueueEntry

        # If +true+, the processing Thread should exit. See also #terminate?.
        #
        attr_accessor :terminate

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
        #
        def initialize( payload: nil, terminate: false, dropped: nil )
          @terminate = terminate
          @payload   = payload
          @dropped   = dropped
        end

        # Returns +true+ if encountering this queue entry should terminate the
        # processing thread, else +false+ (see #dropped? then #payload).
        #
        def terminate?
          @terminate == true
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
