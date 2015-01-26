########################################################################
# File::    amqp_log_message.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Structured logging onto an AMQP-based queue, via the
#           AMQEndpoint gem. Optional; class is defined only if the
#           supporting AMQEndpoint gem's classes are defined.
#
#           The middleware uses this to put log and error messages
#           on the queue. Interested services use this to read such
#           messages from the queue.
# ----------------------------------------------------------------------
#           20-Nov-2014 (ADH): Created.
########################################################################

module Hoodoo
  class ServiceMiddleware

    begin
      require 'amq-endpoint' # Optional

      # For AMQEndpoint gem users, the AMQPLogMessage class provides an
      # AMQEndpoint::Message subclass used for sending structured log data to
      # the queue. Hoodoo::ServiceMiddleware::StructuredLogger uses this.
      #
      # See the AMQEndpoint gem for more details.
      #
      class AMQPLogMessage < ::AMQEndpoint::Message

        TYPE = 'hoodoo_service_middleware_amqp_log_message'
        ::AMQEndpoint::Message.register_type( TYPE, self )

        # A UUID to assign to this log message. See Hoodoo::UUID::generate.
        #
        attr_accessor :id

        # Logging level. See Hoodoo::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :level

        # Logging component. See Hoodoo::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :component

        # Component log code. See Hoodoo::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :code

        # Log payload. See Hoodoo::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :data

        # Optional calling client ID, via session data inside the payload - see
        # Hoodoo::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :client_id

        # Optional interaction UUID, via session data inside the payload - see
        # Hoodoo::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :interaction_id

        # Optional participant UUID, via session data inside the payload - see
        # Hoodoo::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :participant_id

        # Optional outlet UUID, via session data inside the payload - see
        # Hoodoo::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :outlet_id

        # Create an instance with options keyed on the attributes defined for
        # the class.
        #
        def initialize(options = {})
          update( options )
          super( options )

          @type = AMQPLogMessage::TYPE
        end

        # Seralize this instance. See the AMQEndpoint gem and
        # AMQEndpoint::Message#serialize.
        #
        def serialize
          @content = {
            :id             => @id,
            :level          => @level,
            :component      => @component,
            :code           => @code,

            :data           => @data,

            :client_id      => @client_id,
            :interaction_id => @interaction_id,
            :participant_id => @participant_id,
            :outlet_id      => @outlet_id,
          }

          super
        end

        # Unpack a serialized representation into this instance. See the
        # AMQEndpoint gem and AMQEndpoint::Message#deserialize.
        #
        def deserialize
          super
          update( @content )
        end

        # Set public attribute values according to an options hash keyed on
        # the attributes defined for the class.
        #
        def update( options )
          @id             = options[ :id             ]
          @level          = options[ :level          ]
          @component      = options[ :component      ]
          @code           = options[ :code           ]

          @data           = options[ :data           ]

          @client_id      = options[ :client_id      ]
          @interaction_id = options[ :interaction_id ]
          @participant_id = options[ :participant_id ]
          @outlet_id      = options[ :outlet_id      ]
        end
      end

    rescue LoadError # Optional file 'amq-endpoint' is absent
    end

  end
end
