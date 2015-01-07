########################################################################
# File::    amqp_log_writer.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Structured logging support for the middleware.
# ----------------------------------------------------------------------
#           20-Nov-2014 (ADH): Created.
#           16-Dec-2014 (ADH): Changed into a new ApiTools::Logger style
#                              instantiable log writer.
########################################################################

module ApiTools
  class ServiceMiddleware

    # Log writer which sends structured messages to an AMQP-based queue via the
    # Alchemy and AMQEndpoint gems. An ApiTools::Logger::FastWriter subclass,
    # since though talking to the queue might be comparatively slow, Alchemy
    # itself uses an asynchronous Thread for this so there's no need to add
    # another one for this logger.
    #
    # See also ApiTools::Logger and ApiTools::ServiceMiddleware::AMQPLogMessage.
    #
    class AMQPLogWriter < ApiTools::Logger::FastWriter

      # Create an AMQP logger instance.
      #
      # +alchemy+::    The Alchemy endpoint to use for sending messages to the
      #                AMQP-based queue.
      #
      # +queue_name+:: The queue name (as a String) to use. Optional. If
      #                omitted, reads +ENV[ 'AMQ_LOGGING_ENDPOINT' ]+ or if
      #                that is unset, defaults to +platform.logging+.
      #
      # If you're running with Rack on top of Alchemy, then the +call+ method's
      # +env+ parameter containing the Rack environment should have a key of
      # +rack.alchemy+ or +alchemy+ with a value that can be assigned to the
      # +alchemy+ parameter. The logger will then use the active Alchemy
      # service to send messages to its configured named queue.
      #
      def initialize( alchemy, queue_name = nil )
        @alchemy    = alchemy
        @queue_name = queue_name || ENV[ 'AMQ_LOGGING_ENDPOINT' ] || 'platform.logging'
      end

      # Custom implementation of the ApiTools::Logger::WriterMixin#report
      # interface. See that method for parameter details.
      #
      # The middleware custom logger has expectations about the data payload.
      # It expects these optional but recommended (where the information is
      # available / has been generated) keys/values:
      #
      # +:id+::      A UUID (via ApiTools::UUID::generate) to use for this log
      #              message - if absent, one is generated automatically.
      #
      # +:session+:: Description of the current request session when available;
      #              an ApiTools::ServiceSession instance. The client ID,
      #              participant UUID and outlet UUID are sent as independent,
      #              searchable fields in the log payload.
      #
      # +interaction_id+:: The interaction ID for this client's call. This is
      #                    also sent as an independent, searchable field in
      #                    the log payload.
      #
      def report( level, component, code, data )
        return if @alchemy.nil? || defined?( ApiTools::ServiceMiddleware::AMQPLogMessage ).nil?

        data[ :id ] ||= ApiTools::UUID.generate()

        interaction_id = data[ :interaction_id ]
        session        = data[ :session ] || {}
        client_id      = session[ :client_id      ]
        participant_id = session[ :participant_id ]
        outlet_id      = session[ :outlet_id      ]

        message = ApiTools::ServiceMiddleware::AMQPLogMessage.new(
          :id             => data[ :id ],
          :level          => level,
          :component      => component,
          :code           => code,

          :data           => data,

          :client_id      => client_id,
          :interaction_id => interaction_id,
          :participant_id => participant_id,
          :outlet_id      => outlet_id,

          :routing_key    => @queue_name,
        )

        @alchemy.send_message( message )
      end
    end
  end
end