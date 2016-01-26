########################################################################
# File::    by_flux.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Discover resource endpoint locations via Alchemy Flux.
# ----------------------------------------------------------------------
#           03-Mar-2015 (ADH): Created.
#           21-Jan-2016 (ADH): Reimplemented for Alchemy Flux.
########################################################################

module Hoodoo
  module Services
    class Discovery # Just used as a namespace here

      # Discover resource endpoint locations via Alchemy Flux.
      #
      # For Flux, it's less about discovery as it is about convention
      # and announcing. We have to set some system variables when the
      # application starts up, _before_ the Rack `run` call gets as
      # far as the Alchemy Flux server's implementation - in practice
      # this means announcement needs to happen from the Hoodoo
      # middleware's constructor, synchronously. The environment
      # variables tell Flux about this local service's URI-located
      # endpoints and derive a consistent, replicable 'service name'
      # from the resources which the service implements.
      #
      # Once all that is set up, the local Alchemy instance knows how
      # to listen for relevant messages for 'this' service on the queue
      # and Hoodoo in 'this' service knowns which resources are local,
      # or which are remote; and it knows that Flux is able in turn to
      # use URI-based to-resource communications for inter-resource
      # calls without any further explicit discovery within Hoodoo
      # beyond simply saying "here's the AMQP Flux endpoint class".
      #
      class ByFlux < Hoodoo::Services::Discovery

        protected

          # Announce the location of an instance to Alchemy Flux.
          #
          # Call via Hoodoo::Services::Discovery::Base#announce.
          #
          # +resource+:: Passed to #discover_remote.
          # +version+::  Passed to #discover_remote.
          # +options+::  See below.
          #
          # The Options hash informs the announcer of the intended endpoint
          # base URI for the resource and also, where available, provides a
          # head-up on the full range of resource _names_ that will be
          # present in this single service application (see
          # Hoodoo::Services::Service::comprised_of). Keys MUST be Symbols.
          # Associated required values are:
          #
          # +services+:: Array of Hoodoo::Services::Discovery::ForLocal
          #              instances describing available resources in this
          #              local service.
          #
          def announce_remote( resource, version, options = {} )

            alchemy_resource_paths = ENV[ 'ALCHEMY_RESOURCE_PATHS' ]
            alchemy_service_name   = ENV[ 'ALCHEMY_SERVICE_NAME'   ]

            # Under Flux, we "announce" via a local environment variable when
            # this service awakens which tells Flux what to listen for on the
            # AMQP queue.
            #
            # Since inbound HTTP calls into the architecture are based on URIs
            # and paths, there needs to be a mapping at that point to queue
            # endpoints. Historically Hoodoo adopted an (in hindsight, unwise)
            # approach of "/v<version>/<pluralised_resource>" c.f. Rails,
            # rather than just "/<version>/<resource>" - e.g. there was
            # "/v1/members" instead of "/1/Member". This means things like the
            # "ByConvention" discoverer have to use pluralisation rules and
            # exceptions. It's messy.
            #
            # To clean things up, the work on Alchemy Flux sets up *two* paths
            # in Hoodoo - the old one for backwards compatibility, and a new
            # one of the above simpler form. Now it's easy to go from version
            # and resource name to path or back internally with no mappings.
            #
            if ( alchemy_resource_paths.nil? ||
                 alchemy_resource_paths.strip.empty? )

              services = options[ :services ] || []
              paths    = []

              services.each do | service |
                custom_path   = service.base_path
                de_facto_path = service.de_facto_base_path

                paths << custom_path << de_facto_path
              end

              ENV[ 'ALCHEMY_RESOURCE_PATHS' ] = paths.join( ',' )
            end

            if ( alchemy_service_name.nil? ||
                 alchemy_service_name.strip.empty? )
              ENV[ 'ALCHEMY_SERVICE_NAME' ] = Hoodoo::Services::Middleware::service_name()
            end

            return discover_remote( resource, version )
          end

          # Discover the location of an instance.
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
            de_facto_path = Hoodoo::Services::Middleware::de_facto_path_for(
              resource,
              version
            )

            return Hoodoo::Services::Discovery::ForAMQP.new(
              resource: resource,
              version:  version
            )
          end

      end
    end
  end
end
