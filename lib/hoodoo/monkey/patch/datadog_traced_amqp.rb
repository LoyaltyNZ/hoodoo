########################################################################
# File::    datadog_traced_amqp.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Extend the AMQP endpoint to support Datadog cross-app
#           transaction tracing. Only defined and registered if the
#           Datadog gem is available and Hoodooo Client is in scope.
#
#           See Hoodoo::Monkey::Patch::DatadogTracedAMQP for more.
# ----------------------------------------------------------------------
#           22-June-2017 (JRW): Created.
########################################################################

module Hoodoo
  module Monkey
    module Patch

      begin
        require 'ddtrace' # Raises LoadError if Datadog is absent

        # Wrap Hoodoo::Client::Endpoint::AMQP using Datadog transaction
        # tracing so that over-queue inter-resource calls get connected
        # together in Datadogs's view of the world.
        #
        # This module self-registers with Hooodoo::Monkey and, provided
        # that Hoodoo::Services::Middleware is defined at parse-time,
        # will be enabled by default.
        #
        module DatadogTracedAMQP

          # Instance methods to patch over Hoodoo::Client::Endpoint::AMQP.
          #
          module InstanceExtensions

            # Wrap the request with Datadog's distributed tracing.
            # This adds headers to the request and extracts header data from
            # the response. It calls the original implementation via +super+.
            #
            # +http_message+:: Hash describing the message to send.
            # +full_uri+::     URI being sent to. This is somewhat meaningless
            #                  when using AMQP but useful for analytics data.
            #
            def monkey_send_request( http_message, full_uri )
              amqp_response = nil

              Datadog.tracer.trace( 'alchemy.request' ) do |span|
                span.service   = 'alchemy'
                span.span_type = 'alchemy'
                span.resource  = http_message[ 'verb' ]
                span.set_tag( 'target.path', http_message[ 'path'] )

                # Add Datadog trace IDs to the HTTP message. For compatibility
                # with Hoodoo V1 services using a fork of DDTrace, we send both
                # old headers ("X-DDTrace...") and new ("X-DataDog-...")

                http_message[ 'headers' ][ 'X_DATADOG_TRACE_ID'        ] = span.trace_id.to_s
                http_message[ 'headers' ][ 'X_DATADOG_PARENT_ID'       ] = span.span_id.to_s

                http_message[ 'headers' ][ 'X_DDTRACE_PARENT_TRACE_ID' ] = span.trace_id.to_s
                http_message[ 'headers' ][ 'X_DDTRACE_PARENT_SPAN_ID'  ] = span.span_id.to_s

                amqp_response = super( http_message, full_uri )
              end

              return amqp_response
            end
          end
        end

        # Register this class with the Hoodoo monkey patch engine.
        #
        if defined?( Hoodoo::Client ) &&
           defined?( Hoodoo::Client::Endpoint ) &&
           defined?( Hoodoo::Client::Endpoint::AMQP )

          Hoodoo::Monkey.register(
              target_unit:      Hoodoo::Client::Endpoint::AMQP,
              extension_module: Hoodoo::Monkey::Patch::DatadogTracedAMQP
          )

          if defined?( Hoodoo::Services ) &&
             defined?( Hoodoo::Services::Middleware )

            Hoodoo::Monkey.enable( extension_module: Hoodoo::Monkey::Patch::DatadogTracedAMQP )
          end
        end

      rescue LoadError
        # No Datadog => do nothing
      end

    end # module Patch
  end   # module Monkey
end     # module Hoodoo
