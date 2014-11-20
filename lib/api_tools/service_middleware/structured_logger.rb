########################################################################
# File::    structured_logger.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Structured logging support for the middleware.
# ----------------------------------------------------------------------
#           20-Nov-2014 (ADH): Created.
########################################################################

module ApiTools
  class ServiceMiddleware

    # Å custom logger assigned via ApiTools::Logger::logger= which sends log
    # data to an AMQP-based queue via the AMQEndpoint gem if available, else
    # gives up and dumps to flat file. See class
    # ApiTools::ServiceMiddleware::AMQPLogMessage for more information.
    #
    class StructuredLogger

      @@queue_endpoint = nil

      def self.queue_endpoint=( endpoint )
        @@queue_endpoint = endpoint
      end

      # Custom implementation of the ApiTools::Logger::report interface. The
      # middleware custom logger has expectations about the data payload - it
      # expects these optional keys/values:
      #
      # +:id+::      A UUID (via ApiTools::UUID::generate) to use for this log
      #              message - if absent, one is generated automatically.
      #
      # +:session+:: Description of the current request session when available;
      #              an ApiTools::ServiceSession instance.
      #
      # +interaction_id+:: The interaction ID for this client call.
      #
      # If expects these mandatory keys/values:
      #
      # +payload+::  A Hash of other arbitrary data to log.
      #
      def self.report( level, component, code, data )
        if @@queue_endpoint.nil? == false && defined?( ApiTools::ServiceMiddleware::AMQPLogMessage )
          data[ :id ] ||= piTools::UUID.generate()
          message = ApiTools::ServiceMiddleware::AMQPLogMessage.new(
            :id        => data[ :id ],
            :level     => level,
            :component => component,
            :code      => code,
            :data      => data
          )
        else
          $stdout.puts( "#{ level.to_s.upcase }  #{ component }.#{ code }: #{ data.inspect }" )
        end
      end
    end
  end
end
