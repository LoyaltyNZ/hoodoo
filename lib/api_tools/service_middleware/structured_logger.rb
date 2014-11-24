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

      # See ::alchemy= for details.
      #
      @@alchemy = nil

      # Record the logging queue, or use a default.
      #
      @@queue = ENV[ 'AMQ_LOGGING_ENDPOINT' ] || 'platform.logging'

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
      def self.alchemy=( endpoint )
        @@alchemy = endpoint
      end

      # Custom implementation of the ApiTools::Logger::report interface. See
      # that method for parameter details.
      #
      # The middleware custom logger has expectations about the data payload.
      # It expects these optional but recommended (where the information is
      # available / has been generated) keys/values:
      #
      # +:id+::      A UUID (via ApiTools::UUID::generate) to use for this log
      #              message - if absent, one is generated automatically.
      #
      # +:session+:: Description of the current request session when available;
      #              an ApiTools::ServiceSession instance. The participant and
      #              outlet IDs are sent as independent, searchable fields in
      #              the log payload.
      #
      # +interaction_id+:: The interaction ID for this client call. This is
      #                    also sent as an independent, searchable field in
      #                    the log payload.
      #
      def self.report( level, component, code, data )
        if @@alchemy.nil? || defined?( ApiTools::ServiceMiddleware::AMQPLogMessage ).nil?
          $stdout.puts( "#{ level.to_s.upcase }  #{ component }.#{ code }: #{ data.inspect }" )

        else
          data[ :id ] ||= ApiTools::UUID.generate()

          interaction_id = data[ :interaction_id ]
          session        = data[ :session ] || {}
          participant_id = session[ :participant_id ]
          outlet_id      = session[ :outlet_id      ]

          message = ApiTools::ServiceMiddleware::AMQPLogMessage.new(
            :id             => data[ :id ],
            :level          => level,
            :component      => component,
            :code           => code,

            :data           => data,

            :interaction_id => interaction_id,
            :participant_id => participant_id,
            :outlet_id      => outlet_id,

            :routing_key    => @@queue,
          )

          @@alchemy.send_message( message )

          env = ApiTools::ServiceMiddleware.environment()
          if env.test? || env.development?
            $stdout.puts( "ECHO #{ level.to_s.upcase }  #{ component }.#{ code }" )
          end

        end
      end
    end
  end
end
