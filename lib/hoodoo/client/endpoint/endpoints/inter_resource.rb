########################################################################
# File::    endpoint.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Resource endpoint definition.
# ----------------------------------------------------------------------
#           05-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Client
    class Endpoint # Just used as a namespace here



      the client gets things like a base URI so it knows what kind of
      discoverer to set up internally

      when the client creates an endpoint it needs to know the return
      type of the discoverer and thus whether it wants an HTTP or
      AMQP endpoint

      or more to the point - it wants an AMQP endpoint if it has an
      AMQP discoverer and an HTTP endpoint with an HTTP discoverer

      it could run discovery at the time of endpoint creation, so that it
      can configure the endpoint with that resource; or the discoverer
      could be passed in as a standard interface, so that the endpoint
      can do the discovery and self-configure.


        maybe you ask the Endpoint for a subclass as a factory and it
        examines the discoverer output to determine the kind of
        endpoint that you need. It could return (say) "nil" if the
        resource is described as locally available according to your
        chosen discoverer.

        Endpoint.endpoint_for( resource, version, discoverer )




        this means context.resource would need to know the discoverer
        chosen by the middleware so it could pass that through and
        in turn the inter-resource endpoint would



      # Used by Hoodoo::Service::Context to encapsulate information
      # needed for an inter-resource call from one resource
      # implementation to another. From the caller's perspective,
      # the operation looks the same whether the target resource is
      # in the same application or another application and if so, the
      # transport (e.g. HTTP, AMQP) is irrelevant to the caller too.
      #
      class InterResource < Hoodoo::Client::Endpoint

        protected

          # See Hoodoo::Client::Endpoint#configure_with.
          #
          def configure_with( resource, version, discovery_result )



            ForInteraction discovery result?



            @resource           = resource
            @version            = version

            @owning_interaction = options[ :owning_interaction ]
            @owning_middleware  = options[ :owning_interaction.owning_middleware_instance ]

            @local_service      = @owning_middleware.local_service_for( @resource, @version )
            @remote_info        = @owning_middleware.remote_service_for( @resource, @version )

            # ...noting that @remote_info contains an instance of one of the
            # Hoodoo::Services::Discovery::For... class family.
            #
            # See Hoodoo::Services::Middleware#remote_service_for for more.

          end

        public

          # See Hoodoo::Client::Endpoint#list.
          #
          def list( query_hash = nil )
            return @owning_middleware.inter_resource(
              :source_interaction => @owning_interaction,
              :local              => @local_service,
              :remote             => @remote_info,

              :resource           => @resource,
              :version            => @version,

              :http_method        => 'GET',
              :query_hash         => query_hash
            )
          end

          # See Hoodoo::Client::Endpoint#show.
          #
          def show( ident, query_hash = nil )
            return @owning_middleware.inter_resource(
              :source_interaction => @owning_interaction,
              :local              => @local_service,
              :remote             => @remote_info,

              :resource           => @resource,
              :version            => @version,

              :http_method        => 'GET',
              :ident              => ident,
              :query_hash         => query_hash
            )
          end

          # See Hoodoo::Client::Endpoint#create.
          #
          def create( body_hash, query_hash = nil )
            return @owning_middleware.inter_resource(
              :source_interaction => @owning_interaction,
              :local              => @local_service,
              :remote             => @remote_info,

              :resource           => @resource,
              :version            => @version,

              :http_method        => 'POST',
              :body_hash          => body_hash,
              :query_hash         => query_hash
            )
          end

          # See Hoodoo::Client::Endpoint#update.
          #
          def update( ident, body_hash, query_hash = nil )
            return @owning_middleware.inter_resource(
              :source_interaction => @owning_interaction,
              :local              => @local_service,
              :remote             => @remote_info,

              :resource           => @resource,
              :version            => @version,

              :http_method        => 'PATCH',
              :ident              => ident,
              :body_hash          => body_hash,
              :query_hash         => query_hash
            )
          end

          # See Hoodoo::Client::Endpoint#delete.
          #
          def delete( ident, query_hash = nil )
            return @owning_middleware.inter_resource(
              :source_interaction => @owning_interaction,
              :local              => @local_service,
              :remote             => @remote_info,

              :resource           => @resource,
              :version            => @version,

              :http_method        => 'DELETE',
              :ident              => ident,
              :query_hash         => query_hash
            )
          end

      end
    end
  end
end
