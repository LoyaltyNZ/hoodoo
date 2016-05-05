########################################################################
# File::    newrelic_middleware_analytics.rb
# (C)::     Loyalty New Zealand 2016
#
# Purpose:: Add custom attributes to NewRelic transactions and improve
#           visibility over the time spent in implementations separately
#           from the time spent in middleware.
#
#           See Hoodoo::Monkey::Patch::NewRelicMiddlewareAnalytics for
#           more.
# ----------------------------------------------------------------------
#           06-May-2016 (RJS): Created.
########################################################################

module Hoodoo
  module Monkey
    module Patch

      begin
        require 'newrelic_rpm' # Raises LoadError if NewRelic is absent

        # Add a method tracer on the dispatch method so that the time spent
        # executing middleware can be distinguished from the time spent
        # executing the service implementation.
        #
        module Hoodoo
          module Services
            class Middleware
              require 'new_relic/agent/method_tracer'
              include ::NewRelic::Agent::MethodTracer

              add_method_tracer :dispatch, 'Custom/dispatch'
            end
          end
        end

        # This module adds custom attributes to NewRelic transaction traces such
        # that transactions can be filtered by target resource and request
        # action.
        #
        # This module self-registers with Hooodoo::Monkey and, provided
        # that Hoodoo::Services::Middleware is defined at parse-time,
        # will be enabled by default.
        #
        module NewRelicMiddlewareAnalytics

          # Instance methods to patch over Hoodoo::Services::Middleware.
          #
          module InstanceExtensions

            # Add custom attributes to the NewRelic transaction. The original
            # implementation is called via +super+.
            #
            # +interaction+:: Hoodoo::Services::Interaction describing the
            #                 inbound request. The +interaction_id+,
            #                 +rack_request+ and +session+ data is used (the
            #                 latter being optional). If +target_interface+ and
            #                 +requested_action+ are available, body data
            #                 _might_ be logged according to secure log settings
            #                 in the interface; if these values are unset, body
            #                 data is _not_ logged.
            #
            def monkey_log_inbound_request( interaction )

              # Add custom attributes to the NewRelic transaction.
              ::NewRelic::Agent.add_custom_attributes(
                {
                  :target_action => interaction.requested_action,
                  :target_path   => interaction.target_interface.endpoint.try( :to_s )
                }
              )

              # Call the original logging method.
              super( interaction )

            end
          end

        end

        if defined?( Hoodoo::Services ) &&
           defined?( Hoodoo::Services::Middleware )

          ::Hoodoo::Monkey.register(
            target_unit:      Hoodoo::Services::Middleware,
            extension_module: Hoodoo::Monkey::Patch::NewRelicMiddlewareAnalytics
          )

          ::Hoodoo::Monkey.enable( extension_module: Hoodoo::Monkey::Patch::NewRelicMiddlewareAnalytics )
        end

      rescue LoadError
        # No NewRelic => do nothing
      end

    end # module Patch
  end   # module Monkey
end     # module Hoodoo
