########################################################################
# File::    amqp_log_writer.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Structured logging support for the middleware.
# ----------------------------------------------------------------------
#           20-Nov-2014 (ADH): Created.
#           16-Dec-2014 (ADH): Changed into a new Hoodoo::Logger style
#                              instantiable log writer.
########################################################################

module Hoodoo; module Services
  class Middleware

    # Log writer which sends structured messages to an AMQP-based queue via
    # the Alchemy Flux gem. A Hoodoo::Logger::FastWriter subclass, since though
    # talking to the queue might be comparatively slow, Flux uses Event Machine
    # for this so there's no need to add another Thread for this logger.
    #
    # See also Hoodoo::Logger.
    #
    class AMQPLogWriter < Hoodoo::Logger::FastWriter

      # Create an AMQP logger instance.
      #
      # +alchemy+::     The Alchemy endpoint to use for sending messages to the
      #                 AMQP-based queue.
      #
      # +routing_key+:: The routing key (as a String) to use. Optional. If
      #                 omitted, reads +ENV[ 'AMQ_LOGGING_ENDPOINT' ]+ or if
      #                 that is unset, defaults to +platform.logging+.
      #
      # If you're running with Rack on top of Alchemy, then the +call+ method's
      # +env+ parameter containing the Rack environment should have a key of
      # +rack.alchemy+ or +alchemy+ with a value that can be assigned to the
      # +alchemy+ parameter. The logger will then use the active Alchemy
      # service to send messages to its configured routing key.
      #
      def initialize( alchemy, routing_key = nil )
        @alchemy     = alchemy
        @routing_key = routing_key || ENV[ 'AMQ_LOGGING_ENDPOINT' ] || 'platform.logging'
      end

      # Custom implementation of the Hoodoo::Logger::WriterMixin#report
      # interface. See that method for parameter details.
      #
      # The middleware custom logger has expectations about the data payload.
      # It expects these optional but recommended (where the information is
      # available / has been generated) keys/values:
      #
      # +:id+::      A UUID (via Hoodoo::UUID::generate) to use for this log
      #              message - if absent, one is generated automatically.
      #
      # +:session+:: Description of the current request session when available;
      #              a Hoodoo::Services::Session as a Hash (via #to_h; keys as
      #              Strings). The Caller UUID, identity Participant UUID and
      #              identity Outlet UUID are sent as independent, searchable
      #              fields in the log payload.
      #
      # +interaction_id+:: The interaction ID for this client's call. This is
      #                    also sent as an independent, searchable field in
      #                    the log payload.
      #
      def report( level, component, code, data )
        return if @alchemy.nil?

        # Take care with Symbol keys in 'data' vs string keys in e.g. 'Session'.

        data[ :id ] ||= Hoodoo::UUID.generate()

        session = data[ :session ] || {}
        message = Hoodoo::Services::Middleware::AMQPLogMessage.new( {

          :id             => data[ :id ],
          :level          => level,
          :component      => component,
          :code           => code,
          :reported_at    => Time.now,

          :data           => data,

          :interaction_id => data[ :interaction_id ],
          :caller_id      => session[ 'caller_id' ],
          :identity       => ( session[ 'identity' ] || {} ).to_h

        } ).to_h()

        @alchemy.send_message_to_queue( @routing_key, message )
      end
    end

  end
end; end
