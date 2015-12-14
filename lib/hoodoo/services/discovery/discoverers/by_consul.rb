########################################################################
# File::    by_consul.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Discover resource endpoint locations via a registry held in
#           Consul. For AMQP-based endpoints; maps paths to queue names.
#           PLACEHOLDER: NOT YET IMPLEMENTED.
# ----------------------------------------------------------------------
#           03-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services
    class Discovery # Just used as a namespace here

      # Discover resource endpoint locations via a registry held in
      # Consul. For AMQP-based endpoints; maps paths to queue names.
      #
      class ByConsul < Hoodoo::Services::Discovery

        protected

          # Announce the location of an instance to Consul.
          #
          # Call via Hoodoo::Services::Discovery::Base#announce.
          #
          # TODO: NOT YET IMPLEMENTED. Placeholder only.
          #
          # +resource+:: Passed to #discover_remote.
          # +version+::  Passed to #discover_remote.
          # +options+::  Ignored. TODO: Queue name, equivalent path.
          #
          def announce_remote( resource, version, options = {} )
            return discover_remote( resource, version ) # TODO: Replace
          end

          # Discover the location of an instance using Consul.
          #
          # TODO: This currently doesn't use Consul at all! It has a
          # TODO: hard-coded mapping.
          #
          # Returns a Hoodoo::Services::Discovery::ForAMQP instance if
          # the endpoint is found, else +nil+.
          #
          # Call via Hoodoo::Services::Discovery::Base#announce.
          #
          # +resource+:: Passed to #discover_remote.
          # +version+::  Passed to #discover_remote.
          #
          def discover_remote( resource, version )

            queue = "service.#{ resource.to_s.downcase }"
            path  = "/v#{ version }/#{ resource.to_s.downcase.pluralize }"

            return Hoodoo::Services::Discovery::ForAMQP.new(
              resource:        resource,
              version:         version,
              queue_name:      queue,
              equivalent_path: path
            )
          end

      end
    end
  end
end
