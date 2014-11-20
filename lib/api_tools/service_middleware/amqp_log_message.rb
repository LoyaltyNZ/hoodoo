########################################################################
# File::    amqp_log_message.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Structured logging onto an AMQP-based queue, via the
#           AMQEndpoint gem. Optional; class is defined only if the
#           supporting AMQEndpoint gem's classes are defined.
# ----------------------------------------------------------------------
#           20-Nov-2014 (ADH): Created.
########################################################################

if defined?( AMQEndpoint ) && defined?( AMQEndpoint::Message )

  module ApiTools
    class ServiceMiddleware

      # For AMQEndpoint gem users, the AMQPLogMessage class provides an
      # AMQEndpoint::Message subclass used for sending structured log data to
      # the queue. ApiTools::ServiceMiddleware::StructuredLogger uses this.
      #
      # See the AMQEndpoint gem for more details.
      #
      class AMQPLogMessage < AMQEndpoint::Message
      end
    end
  end

end
