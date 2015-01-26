########################################################################
# File::    s;pw.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A slow communication-orientated object intended to be called
#           asynchronously via Hoodoo::Communicators::Pool.
# ----------------------------------------------------------------------
#           15-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Communicators

    # See Hoodoo::Communicators::Pool for details.
    #
    # A "slow communicator". Subclass this to create a class where instances
    # are invoked via Hoodoo::Communicators::Slow#communicate with some
    # parameter and, in response, they talk to some other piece of software to
    # communicate information related to that parameter. The communication is
    # expected to be slow and might involve blocking I/O network calls. An
    # instance of the class is called from a Thread with this in mind.
    #
    # If you expect your communicator subclass to always perform very quickly,
    # the Thread will introduce overhead that may actually slow down overall
    # system performance. Avoid this by creating a subclass of
    # Hoodoo::Communicators::Fast instead.
    #
    # Example: A communicator might be part of a logging scheme which talks to
    # a network-based third party logging service. The parameter it expects
    # would be a log message string.
    #
    # *IMPORTANT*: If you use ActiveRecord in a slow communicator class, beware
    # that your writer runs in a ruby Thread. Unless you take steps to prevent
    # it, ActiveRecord will implicitly check out a connection which stays with
    # your Thread forever. This steals a connection from the pool. To prevent
    # this issue, you must use the following pattern:
    #
    #     def communicate( object )
    #       ActiveRecord::Base.connection_pool.with_connection do
    #         # ...Any AciveRecord code goes here...
    #       end
    #     end
    #
    # Code within the +with_connection+ block uses a temporary connection from
    # the pool which is returned once the block has finished processing. Even
    # if exceptions occur within your ActiveRecord code, the connection is
    # still correctly returned to the pool using the above approach.
    #
    class Slow

      # Communicate (possibly slowly) with the piece of external software for
      # which your subclass is designed. Subclasses _must_ implement this
      # method. There is no need to call +super+ in your implementation.
      #
      # If a slow communicator can't keep up with the incoming message rate,
      # messages may be dropped. Implement #dropped if you want to detect this
      # condition.
      #
      # +object+:: Parameter sent by the communication pool, in response to
      #            someone calling Hoodoo::Communicators::Pool#communicate
      #            with that value.
      #
      def communicate( object )
        raise( 'Subclasses must implement #communicate' )
      end

      # This method is called _before_ #communicate if messages have been
      # dropped prior to the one which #communicate is about to report. Should
      # you care, your subclass can implement this method and take whatever
      # action it wants (e.g. log that messages were discarded).
      #
      # The default implementation does nothing; there is no need to call
      # +super+ in custom implementations.
      #
      # +count+:: Number of messages dropped between the previous call to
      #           #communicate and the call which is about to be made.
      #
      def dropped( count )
        # This Implementation Intentionally Left Blank
      end

    end
  end
end
