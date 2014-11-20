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

        # A UUID to assign to this log message. See ApiTools::UUID::generate.
        #
        attr_accessor :id

        # Logging level. For a level of +:error+, the queue packet type will be
        # 'error'. For anything else, the packet type will be determined by
        # options but default to 'log'.
        #
        # See also ApiTools::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :level

        # Logging component. See ApiTools::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :component

        # Component log code. See ApiTools::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :code

        # Log payload. See ApiTools::ServiceMiddleware::StructuredLogger.
        #
        attr_accessor :data

        # Create an instance with options keyed on the attributes defined for
        # the class. In addition, option +:type+ can be used to override the
        # internally set queue packet type of 'log' or 'error'. The value must
        # be a String.
        #
        def initialize(options = {})
          update( options )
          super( options )

          @type = if options[ :level ] == :error
            'error'
          else
            options[ :type ] || 'log'
          end
        end

        # Seralize this instance. See the AMQEndpoint gem and
        # AMQEndpoint::Message#serialize.
        #
        def serialize
          @content = {
            :id        => @id,
            :level     => @level,
            :component => @component,
            :code      => @code,
            :data      => @data,
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
          @id        = options[ :id        ]
          @level     = options[ :level     ]
          @component = options[ :component ]
          @code      = options[ :code      ]
          @data      = options[ :data      ]
        end
      end
    end
  end

end
