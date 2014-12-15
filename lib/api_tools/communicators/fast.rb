########################################################################
# File::    fast.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A fast communication-orientated object intended to be called
#           synchronously via ApiTools::Communicators::Pool.
# ----------------------------------------------------------------------
#           15-Dec-2014 (ADH): Created.
########################################################################

module ApiTools
  module Communicators

    # A "fast communicator". Subclass this to create a class where instances
    # are invoked via ApiTools::Communicators::Fast#communicate with some
    # parameter and, in response, they talk to some other piece of software to
    # communicate information related to that parameter. The communication is
    # expected to be fast and will be called from Ruby's main execution thread.
    #
    # If the communicator takes a long time to complete its operation, other
    # processing will be delayed. If you expect this to happen, subclass
    # ApiTools::Communicators::Slow instead.
    #
    # Example: A communicator might be part of a logging scheme which writes
    #          to STDOUT. The parameter it expects would be a log message
    #          string.
    #
    class Fast

      # Communicate quickly with the piece of external software for which your
      # subclass is designed. Subclasses _must_ implement this method. There is
      # no need to call +super+ in your implementation.
      #
      # +object+:: Parameter sent by the communication pool, in response to
      #            someone calling ApiTools::Communicators::Pool#communicate
      #            with that value.
      #
      def communicate( object )
        raise( 'Subclasses must implement #communicate' )
      end
    end
  end
end
