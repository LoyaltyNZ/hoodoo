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

    # A custom logger assigned via ApiTools::Logger::logger= which sends log
    # data to an AMQP-based queue via the AMQEndpoint gem if available, else
    # gives up and dumps to flat file. See class
    # ApiTools::ServiceMiddleware::AMQPLogMessage for more information.
    #
    class StructuredLogger

      # See ::queue_endpoint= for details.
      #
      @@queue_endpoint = nil

      # Set the AMQEndpoint::Service instance used to send messages via
      # instances of the ApiTools::ServiceMiddleware::AMQPLogMessage class. See
      # the AMQEndpoint gem for details.
      #
      # If you're running with Rack on top of Alchemy, then the +call+ method's
      # +env+ parameter containing the Rack environment should have a key of
      # +rack.alchemy+ or +alchemy+ with a value that can be assigned here. The
      # logger will then use the active Alchemy service to send messages to its
      # configured queue.
      #
      def self.queue_endpoint=( endpoint )
        @@queue_endpoint = endpoint
      end

      # Custom implementation of the ApiTools::Logger::report interface. See
      # that method for parameter details.
      #
      # The middleware custom logger has expectations about the data payload.
      # It expects these optional keys/values:
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
          data[ :id ] ||= ApiTools::UUID.generate()
          message = ApiTools::ServiceMiddleware::AMQPLogMessage.new(
            :id        => data[ :id ],
            :level     => level,
            :component => component,
            :code      => code,
            :data      => data
          )
          @@queue_endpoint.send_message( message )
        else
          $stdout.puts( "#{ level.to_s.upcase }  #{ component }.#{ code }: #{ data.inspect }" )
        end
      end
    end
  end
end
