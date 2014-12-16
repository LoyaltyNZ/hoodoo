########################################################################
# File::    amqp_writer.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Write structured log messages to an AMQP-based queue.
# ----------------------------------------------------------------------
#           16-Dec-2014 (ADH): Created.
########################################################################

module ApiTools
  class Logger
    class AMQPWriter < ApiTools::Logger::SlowWriter
      def report( log_level, component, code, data )
      end
    end
  end
end
