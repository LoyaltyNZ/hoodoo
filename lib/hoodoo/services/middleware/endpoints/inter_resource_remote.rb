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

      # This is an endpoint which the middleware uses for inter-resource
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
          # Configuration option keys which _must_ be supplied are:
          #
          # +interaction+::      A Hoodoo::Services::Middleware::Interaction
          #                      instance which describes the *source*
          #                      interaction at hand. This is a middleware
          #                      concept; the middleware is handling some
          #                      API call which the source interaction data
          #                      describes, but the resource which is
          #                      handling the call needs to make a remote
          #                      inter-resource call, which is why this
          #                      Endpoint subclass instance is needed.
          #
          # +discovery_result+:: A Hoodoo::Services::Discovery::ForRemote
          #                      instance describing the remotely available
          #                      resource endpoint.
          #
          # The pattern for creating and using this instance is:
          #
          # * Use the discovery result to build an appropriate Endpoint
          #   subclass instance, e.g. Hoodoo::Client::Endpoint::HTTP.
          #
          # * Create a Hoodoo::Services::Discovery::ForRemote instance
          #   which describes the above endpoint via the +wrapped_endpoint+
          #   option.
          #
          # * Build an instance of this auto-session Endpoint subclass,
          #   giving it the above object as the +discovery_result+.
          #
          # * Use this endpoint in the normal fashion. All the special
          #   mechanics of remote inter-resource calling are handled here.
          #
          def configure_with( resource, version, options )
            @wrapped_endpoint = @discovery_result.wrapped_endpoint
          end

        public

          # See Hoodoo::Client::Endpoint#list.
          #
          def list( query_hash = nil )
            result = preprocess( :list )
            result = @wrapped_endpoint.list( query_hash ) if result.nil?
            return inject_enumeration_state( postprocess( result ), query_hash )
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

          # Preprocess the given action. This, for example, includes setting
          # up a session with extra permissions requested by the *calling*
          # resource implementation's interface, if necessary.
          #
          # +action+:: A Hoodoo::Services::Middleware::ALLOWED_ACTIONS entry.
          #
          def preprocess( action )

            copy_updated_options_to( @wrapped_endpoint )

            # Interaction ID comes from Endpoint superclass.
            #
            session = self.interaction().context.session

            unless session.nil? || self.interaction().using_test_session?
              session = session.augment_with_permissions_for( self.interaction() )
            end

            if session == false
              data = response_class_for( action ).new
              data.platform_errors.add_error( 'platform.invalid_session' )
              return data
            else

              # We only get away with @wrapping_session as an instance
              # variable because endpoints are not intended to be thread
              # safe, so we assume that only one thread at any given time
              # will be running through "this" instance.
              #
              # We only store the full session rather than just the ID so
              # that we can easily delete it. The inbound session which
              # may have been augmented, would already have any relevant
              # configuration data associated with it - so we don't want
              # to lose that reference by only storing the ID. This would
              # make it very hard / impossible to delete the session again
              # in #postprocess, which could represent a security issue as
              # an elevated permission session could be left kicking
              # around somewhere.

              @wrapping_session = session
              @wrapped_endpoint.session_id = session.session_id unless session.nil?
              return nil
            end
          end

          # Postprocess the given action. This, for example, includes
          # removing any session with extra permissions that might have been
          # set up in #preprocess.
          #
          # +action+:: A Hoodoo::Client::AugmentedHash or
          #            Hoodoo::Client::AugmentedArray containing the result
          #            of a previous (successful or unsuccessful) call to a
          #            remote target resource. It may be modified.
          #
          def postprocess( result )

            # Interaction ID comes from Endpoint superclass.
            #
            if @wrapping_session &&
               self.interaction().context &&
               self.interaction().context.session &&
               @wrapping_session.session_id != self.interaction().context.session.session_id

              # Ignore errors, there's nothing much we can do about them and in
              # the worst case we just have to wait for this to expire naturally.

              @wrapped_endpoint.session_id = nil

              session = @wrapping_session
              @wrapping_session = nil
              session.delete_from_store()
            end

            annotate_errors_from_other_resource_in( result )

            return result
          end

          # TODO
          #
          def annotate_errors_from_other_resource_in( augmented_thing )
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
