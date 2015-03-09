########################################################################
# File::    inter_resource_remote.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Resource endpoint definition.
# ----------------------------------------------------------------------
#           05-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services
    class Middleware # Just used as a namespace here

      # This is an endpoint which the Middleware uses for inter-resource
      # calls over another 'wrapped' endpoint. This endpoint manages all
      # the inter-resource preparation and post processing, but calls in
      # to another wrapped endpoint to actually talk to the resource for
      # which the inter-resource call is being made.
      #
      # Since it wraps another endpoint, instantiation requirements are
      # rather unusual - see #configure_with for details.
      #
      class InterResourceRemote < Hoodoo::Client::Endpoint

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
          #                      handling the call needs to make an
          #                      inter-resource call, which is why this
          #                      Endpoint subclass instance is needed.
          #
          # +wrapped_endpoint+:: The Hoodoo::Client::Endpoint subclass
          #                      instance which is being wrapped. This will
          #                      be called to
          #
          # +discovery_result+:: Ignored. The +wrapped_endpoint+ data will
          #                      by definition already have discovery data
          #                      associated with it, else it could not have
          #                      been instantiated in the first place.
          #
          # So, the pattern for creating and using this instance is:
          #
          # * Discover the location of the remote resource.
          #
          # * Use the discovery result to build an appropriate Endpoint
          #   subclass instance.
          #
          # * Build an instance of this inter-resource Endpoint class,
          #   giving it the wrapped endpoint from the above step.
          #
          # * Use this endpoint in the normal fashion. All the special
          #   mechanics of remote inter-resource calling are handled here.
          #
          def configure_with( resource, version, options )
            super( resource, version, options )

            @owning_interaction = options[ :interaction      ]
            @wrapped_endpoint   = options[ :wrapped_endpoint ]
          end

        public

          # See Hoodoo::Client::Endpoint#list.
          #
          def list( query_hash = nil )
            result = preprocess( :list )
            result = @wrapped_endpoint.list( query_hash ) if result.nil?
            return postprocess( result )
          end

          # See Hoodoo::Client::Endpoint#show.
          #
          def show( ident, query_hash = nil )
            result = preprocess( :show )
            result = @wrapped_endpoint.show( ident, query_hash ) if result.nil?
            return postprocess( result )
          end

          # See Hoodoo::Client::Endpoint#create.
          #
          def create( body_hash, query_hash = nil )
            result = preprocess( :create )
            result = @wrapped_endpoint.create( body_hash, query_hash ) if result.nil?
            return postprocess( result )
          end

          # See Hoodoo::Client::Endpoint#update.
          #
          def update( ident, body_hash, query_hash = nil )
            result = preprocess( :update )
            result = @wrapped_endpoint.update( ident, body_hash, query_hash ) if result.nil?
            return postprocess( result )
          end

          # See Hoodoo::Client::Endpoint#delete.
          #
          def delete( ident, query_hash = nil )
            result = preprocess( :delete )
            result = @wrapped_endpoint.delete( ident, query_hash ) if result.nil?
            return postprocess( result )
          end

        private

          def preprocess( action )
            session = @owning_interaction.context.session

            unless session.nil?
              session = session.augment_with_permissions_for( @owning_interaction )
            end

            if session == false
              data = response_class_for( action ).new
              data.platform_errors.add_error( 'platform.invalid_session' )
              return data
            else
              @wrapped_endpoint.session = session
              return nil
            end
          end

          def postprocess( result )
            translate_errors_from_other_resource_in( result )

            if @wrapped_endpoint.session &&
               @owning_interaction.context &&
               @owning_interaction.context.session &&
               @wrapped_endpoint.session.session_id != @owning_interaction.context.session.session_id

              # Ignore errors, there's nothing much we can do about them and in
              # the worst case we just have to wait for this to expire naturally.

              session = @wrapped_endpoint.session
              @wrapped_endpoint.session = nil
              session.delete_from_memcached()
            end
          end

          def translate_errors_from_other_resource_in( augmented_thing )
            # TODO - this probably needs to live somewhere else so the
            # endpoint and middleware local service call can 'reach' it.
            # Run through errors, if any; prefix messages with target resource
            # and version; maybe source resource and version too; e.g.:
            # "In v1 of Bar while handling <action> in v2 of Foo: ..."
          end

      end
    end
  end
end
