########################################################################
# File::    auto_session.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Resource endpoint definition.
# ----------------------------------------------------------------------
#           12-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  class Client     # Just used as a namespace here
    class Endpoint # Just used as a namespace here

      # This endpoint wraps something which does _actual_ communication but
      # requires a session; it maintains a valid session for that wrapped
      # endpoint automatically. It implements the following model:
      #
      # - It requires a Caller ID and Caller Authentication Secret to be
      #   instantiated (via the +options+ parameter).
      #
      # - If there is no session ID available, it creates one using the above
      #   details. Otherwise, it tries to use the given session.
      #
      # - If a particular request leads to an 'invalid session' response, the
      #   request is marked for retry. A new session is obtained first, the
      #   retry happens and if it fails this time, the failure is returned to
      #   the caller.
      #
      # Since it wraps another endpoint and requires Caller information to be
      # able to build sessions, instantiation requirements are rather unusual
      # - see #configure_with for details.
      #
      class AutoSession < Hoodoo::Client::Endpoint

        protected

          # See Hoodoo::Client::Endpoint#configure_with.
          #
          # Configuration option keys which _must_ be supplied are:
          #
          # +caller_id+::        The UUID of the Caller instance to be used
          #                      for session creation.
          #
          # +caller_secret+::    The authentication secret of the Caller
          #                      instance to be used for session creation.
          #
          # +session_endpoint::  A Hooodo::Client::Endpoint subclass which
          #                      can be used for talking to the Session
          #                      endpoint (for obvious reasons!).
          #
          # +discovery_result+:: A Hoodoo::Services::Discovery::ForRemote
          #                      instance describing the required, remotely
          #                      available resource endpoint.
          #
          # The pattern for creating and using this instance is:
          #
          # * Discover the location of the remote resource.
          #
          # * Use the discovery result to build an appropriate Endpoint
          #   subclass instance, e.g. Hoodoo::Client::Endpoint::HTTP.
          #
          # * Create a Hoodoo::Services::Discovery::ForRemote instance which
          #   describes the above endpoint via the +wrapped_endpoint+ option.
          #
          # * Build an instance of this auto-session Endpoint subclass,
          #   giving it the above object as the +discovery_result+.
          #
          # * Use this endpoint in the normal fashion. All the special
          #   mechanics of session management are handled here.
          #
          def configure_with( resource, version, options )
            @caller_id        = options[ :caller_id        ]
            @caller_secret    = options[ :caller_secret    ]
            @session_endpoint = options[ :session_endpoint ]
            @wrapped_endpoint = @discovery_result.wrapped_endpoint
          end

        public

          # See Hoodoo::Client::Endpoint#list.
          #
          def list( query_hash = nil )
            return auto_retry( :list, query_hash )
          end

          # See Hoodoo::Client::Endpoint#show.
          #
          def show( ident, query_hash = nil )
            return auto_retry( :show, ident, query_hash )
          end

          # See Hoodoo::Client::Endpoint#create.
          #
          def create( body_hash, query_hash = nil )
            return auto_retry( :create, body_hash, query_hash )
          end

          # See Hoodoo::Client::Endpoint#update.
          #
          def update( ident, body_hash, query_hash = nil )
            return auto_retry( :update, ident, body_hash, query_hash )
          end

          # See Hoodoo::Client::Endpoint#delete.
          #
          def delete( ident, query_hash = nil )
            return auto_retry( :delete, ident, query_hash )
          end

        private

          # Try to perform an action through the wrapped endpoint, acquiring a
          # session first if need be or if necessary reacquiring a session and
          # retrying the request.
          #
          # +action+:: The name of the method to call in the wrapped endpoint
          #            - see Hoodoo::Services::Middleware::ALLOWED_ACTIONS.
          #
          # *args::    Any other arguments to pass to +action+.
          #
          def auto_retry( action, *args )

            copy_updated_options_to( @wrapped_endpoint )

            # We use the session endpoint as a session ID cache, in essence,
            # storing the acquired ID there and passing it into the wrapped
            # endpoint for the 'real' calls.

            if @session_endpoint.session_id.nil?
              session_creation_result = acquire_session_for( action )
              return session_creation_result unless session_creation_result.nil?
            else
              @wrapped_endpoint.session_id = @session_endpoint.session_id
            end

            result = @wrapped_endpoint.send( action, *args )

            if result.platform_errors.has_errors? &&
               result.platform_errors.errors.size == 1 &&
               result.platform_errors.errors[ 0 ][ 'code' ] == 'platform.invalid_session'

              session_creation_result = acquire_session_for( action )
              return session_creation_result unless session_creation_result.nil?
              return @wrapped_endpoint.send( action, *args )
            else
              return result
            end
          end

          # Acquire a sessino using the configured session endpoint. If this
          # fails, the failure result is returned. If it seems to succeed but
          # a session ID cannot be found, an internal 'generic.malformed'
          # result is generated and returned.
          #
          # The returned data uses an appropriate response class for the
          # action at hand - an augmented array for lists, else an augmented
          # hash. It can be returned directly up to the calling layer.
          #
          # Returns +nil+ if all goes well; #session_id will be updated.
          #
          # +action+:: As given to #auto_retry.
          #
          def acquire_session_for( action )
            session_creation_result = @session_endpoint.create(
              'caller_id'             => @caller_id,
              'authentication_secret' => @caller_secret
            )

            if session_creation_result.platform_errors.has_errors?
              data = response_class_for( action ).new
              data.platform_errors.merge!( session_creation_result.platform_errors )
              return data
            end

            @session_endpoint.session_id = session_creation_result[ 'id' ]

            if @session_endpoint.session_id.nil? || @session_endpoint.session_id.empty?
              data = response_class_for( action ).new
              data.platform_errors.add_error(
                'generic.malformed',
                'message' => 'Received bad session description from Session endpoint despite "200" response code'
              )

              return data
            else
              @wrapped_endpoint.session_id = @session_endpoint.session_id
              return nil
            end
          end

      end
    end
  end
end
