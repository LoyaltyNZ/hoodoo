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

module Hoodoo; module Services
  class Middleware

    begin
      require 'amq-endpoint' # Optional

      # For AMQEndpoint gem users, the AMQPLogMessage class provides an
      # AMQEndpoint::Message subclass used for sending structured log data to
      # the queue. Hoodoo::Services::Middleware::StructuredLogger uses this.
      #
      # See the AMQEndpoint gem for more details.
      #
      class AMQPLogMessage < ::AMQEndpoint::Message

        # The named "type" of this message, to be registered with AMQEndpoint.
        #
        TYPE = 'hoodoo_service_middleware_amqp_log_message'

        # This line of code registers wth AMQEndpoint, but also makes RDoc
        # screw up. RDoc decides that we have a new module,
        # Hoodoo::Services::Middleware::AMQPLogMessage::AMQEndpoint. Very
        # strange...
        #
        ::AMQEndpoint::Message.register_type( TYPE, self )

        # ...so do _this_ purely so that we can get 100% real documentation
        # coverage without it being clouded by RDoc's hiccups.

        # This documentation exists purely to work around an RDoc hiccup where
        # it thinks such a module exists.
        #
        # See file "services/middleware/amqp_log_message.rb" for details.
        #
        module AMQEndpoint
        end

        # A UUID to assign to this log message. See Hoodoo::UUID::generate.
        #
        attr_accessor :id

        # Logging level. See Hoodoo::Services::Middleware::StructuredLogger.
        #
        attr_accessor :level

        # Logging component. See Hoodoo::Services::Middleware::StructuredLogger.
        #
        attr_accessor :component

        # Component log code. See Hoodoo::Services::Middleware::StructuredLogger.
        #
        attr_accessor :code

        # Log payload. See Hoodoo::Services::Middleware::StructuredLogger.
        #
        attr_accessor :data

        # Optional calling client ID, via session data inside the payload - see
        # Hoodoo::Services::Middleware::StructuredLogger.
        #
        attr_accessor :client_id

        # Optional interaction UUID, via session data inside the payload - see
        # Hoodoo::Services::Middleware::StructuredLogger.
        #
        attr_accessor :interaction_id

        # Optional participant UUID, via session data inside the payload - see
        # Hoodoo::Services::Middleware::StructuredLogger.
        #
        attr_accessor :participant_id

        # Optional outlet UUID, via session data inside the payload - see
        # Hoodoo::Services::Middleware::StructuredLogger.
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
end; end
