########################################################################
# File::    amqp_log_message.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Structured logging onto an AMQP-based queue, via the
#           Alchemy Flux gem. This class just exists to rationalise
#           any parameters inbound in order to generate a clean
#           representation for Flux.
#
#           The middleware uses this to put log and error messages
#           on the queue. Interested services use this to read such
#           messages from the queue.
# ----------------------------------------------------------------------
#           20-Nov-2014 (ADH): Created.
########################################################################

module Hoodoo; module Services
  class Middleware

    # A representation of a log message placed on an AMQP-based queue.
    # The primary expected communications interface is Alchemy Flux at
    # the time of writing.
    #
    class AMQPLogMessage

      # The Time +strftime+ formatter used for string conversions in this
      # class.
      #
      TIME_FORMATTER = '%Y-%m-%d %H:%M:%S.%12N %Z'

      # A UUID to assign to this log message. See Hoodoo::UUID::generate.
      #
      attr_accessor :id

      # Logging level. See Hoodoo::Logger.
      #
      attr_accessor :level

      # Logging component. See Hoodoo::Logger.
      #
      attr_accessor :component

      # Component log code. See Hoodoo::Logger.
      #
      attr_accessor :code

      # The time at which this log message is being reported to the Logger
      # instance. This is a formatted *String* to high accuracy. See also
      # #reported_at=.
      #
      attr_reader :reported_at

      # Set the time read back by #reported_at using a Time instance. This
      # is formatted internally as a String via TIME_FORMATTER and reported
      # as such in subsequent calls to #reported_at.
      #
      # Conversion from Time to String is done here, rather than by the
      # caller setting this instance's variables, so that we can internally
      # enforce the accuracy required for this field.
      #
      # +time+:: The Time instance to set (and process into a string
      #          internally via TIME_FORMATTER), *or* a String instance
      #          already so formatted, *or* +nil+ to clear the value.
      #
      def reported_at=( time )
        if time.is_a?( String )
          @reported_at = time
        elsif time.is_a?( Time )
          @reported_at = time.strftime( TIME_FORMATTER )
        else
          @reported_at = nil
        end
      end

      # Log payload. See Hoodoo::Logger.
      #
      attr_accessor :data

      # Optional calling Caller ID, via session data inside the payload - see
      # Hoodoo::Logger.
      #
      attr_accessor :caller_id

      # Optional interaction UUID, via session data inside the payload - see
      # Hoodoo::Logger.
      #
      attr_accessor :interaction_id

      # Optional hash of identity properties from the session data inside the
      # payload - see Hoodoo::Logger.
      #
      attr_accessor :identity

      # Create an instance with options keyed on the attributes defined for
      # the class. Option keys may be Strings or Symbols but must only match
      # defined attribute names.
      #
      def initialize( options = {} )
        options.each do | name, value |
          send( "#{ name }=", value )
        end
      end

      # Retrieve a simple Hash representation of this instance.
      #
      def to_h
        {
          'id'             => @id,
          'level'          => @level,
          'component'      => @component,
          'code'           => @code,
          'reported_at'    => @reported_at,

          'data'           => @data,

          'interaction_id' => @interaction_id,
          'caller_id'      => @caller_id,
          'identity'       => Hoodoo::Utilities.stringify( @identity )
        }
      end
    end

  end
end; end
