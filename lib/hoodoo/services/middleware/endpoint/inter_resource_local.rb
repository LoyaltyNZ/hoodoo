########################################################################
# File::    inter_resource_local.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: An endpoint that calls back into a known middleware
#           instance to communicate with a resource that is available
#           in the local service application.
# ----------------------------------------------------------------------
#           11-Nov-2014 (ADH): Split out from service_middleware.rb
#           09-Mar-2015 (ADH): Adapted from old endpoint.rb code.
########################################################################

module Hoodoo; module Services
  class Middleware

    class InterResourceLocal < Hoodoo::Client::Endpoint

      protected

        # See Hoodoo::Client::Endpoint#configure_with.
        #
        # It isn't expected that anyone will ever need to use this class
        # beyond Hoodoo::Services::Middleware, but you never know...
        #
        # Extra configuration option keys which must be supplied are:
        #
        # +interaction+::      A Hoodoo::Services::Middleware::Interaction
        #                      instance which describes the *source*
        #                      interaction at hand. This is a middleware
        #                      concept; the middleware is handling some
        #                      API call which the source interaction data
        #                      describes, but the resource which is
        #                      handling the call needs to make a local
        #                      inter-resource call, which is why this
        #                      Endpoint subclass instance is needed.
        #
        # +discovery_result+:: A Hoodoo::Services::Discovery::ForLocal
        #                      instance describing the locally available
        #                      resource endpoint.
        #
        def configure_with( resource, version, options )
          super( resource, version, options )

          @owning_interaction = options[ :interaction ]
          @owning_middleware  = owning_interaction.owning_middleware_instance
          @discovery_result   = options[ :discovery_result ]
        end

      public

        # See Hoodoo::Client::Endpoint#list.
        #
        def list( query_hash = nil )
          return @owning_middleware.inter_resource_local(
            :source_interaction => @owning_interaction,
            :discovery_result   => @discovery_result,

            :action             => :list,

            :query_hash         => query_hash
          )
        end

        # See Hoodoo::Client::Endpoint#show.
        #
        def show( ident, query_hash = nil )
          return @owning_middleware.inter_resource_local(
            :source_interaction => @owning_interaction,
            :discovery_result   => @discovery_result,

            :action             => :show,

            :ident              => ident,
            :query_hash         => query_hash
          )
        end

        # See Hoodoo::Client::Endpoint#create.
        #
        def create( body_hash, query_hash = nil )
          return @owning_middleware.inter_resource_local(
            :source_interaction => @owning_interaction,
            :discovery_result   => @discovery_result,

            :action             => :create,

            :body_hash          => body_hash,
            :query_hash         => query_hash
          )
        end

        # See Hoodoo::Client::Endpoint#update.
        #
        def update( ident, body_hash, query_hash = nil )
          return @owning_middleware.inter_resource_local(
            :source_interaction => @owning_interaction,
            :discovery_result   => @discovery_result,

            :action             => :update,

            :ident              => ident,
            :body_hash          => body_hash,
            :query_hash         => query_hash
          )
        end

        # See Hoodoo::Client::Endpoint#delete.
        #
        def delete( ident, query_hash = nil )
          return @owning_middleware.inter_resource_local(
            :source_interaction => @owning_interaction,
            :discovery_result   => @discovery_result,

            :action             => :delete,

            :ident              => ident,
            :query_hash         => query_hash
          )
        end
      end

  end
end; end
