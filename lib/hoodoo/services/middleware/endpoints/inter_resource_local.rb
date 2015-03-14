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

    # This is an endpoint which the middleware uses for inter-resource
    # calls back calling back to that same middleware instance, for
    # resources which exist within the same service application. The
    # middleware manages all the inter-resource preparation and post
    # processing.
    #
    class InterResourceLocal < Hoodoo::Client::Endpoint

      protected

        # See Hoodoo::Client::Endpoint#configure_with.
        #
        # It isn't expected that anyone will ever need to use this class
        # beyond Hoodoo::Services::Middleware, but you never know...
        #
        # Configuration option keys which _must_ be supplied are:
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
          @middleware = self.interaction().owning_middleware_instance
        end

      public

        # See Hoodoo::Client::Endpoint#list.
        #
        def list( query_hash = nil )
          return @middleware.inter_resource_local(
            :source_interaction => self.interaction(),
            :discovery_result   => @discovery_result,

            :action             => :list,

            :query_hash         => query_hash
          )
        end

        # See Hoodoo::Client::Endpoint#show.
        #
        def show( ident, query_hash = nil )
          return @middleware.inter_resource_local(
            :source_interaction => self.interaction(),
            :discovery_result   => @discovery_result,

            :action             => :show,

            :ident              => ident,
            :query_hash         => query_hash
          )
        end

        # See Hoodoo::Client::Endpoint#create.
        #
        def create( body_hash, query_hash = nil )
          return @middleware.inter_resource_local(
            :source_interaction => self.interaction(),
            :discovery_result   => @discovery_result,

            :action             => :create,

            :body_hash          => body_hash,
            :query_hash         => query_hash
          )
        end

        # See Hoodoo::Client::Endpoint#update.
        #
        def update( ident, body_hash, query_hash = nil )
          return @middleware.inter_resource_local(
            :source_interaction => self.interaction(),
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
          return @middleware.inter_resource_local(
            :source_interaction => self.interaction(),
            :discovery_result   => @discovery_result,

            :action             => :delete,

            :ident              => ident,
            :query_hash         => query_hash
          )
        end
      end

  end
end; end
