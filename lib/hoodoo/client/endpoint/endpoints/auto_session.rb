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

          def auto_retry( action, *args )
            result =
            result = @wrapped_endpoint.send( action, *args )
            if result
            end
          end




          def acquire_session
            session_creation_result = @session_endpoint.create(
              'caller_id'             => @caller_id,
              'authentication_secret' => @authentication_secret
            )

            if session_creation_result.platform_errors.has_errors?
              return session_creation_result
            end

            self.session_id = session_creation_result[ 'id' ]

            if self.session_id.nil? || self.session_id.empty?
              session_creation_result.platform_errors.add_error(
                'code' => 'generic.malformed',
                'message' => 'Received bad session description from Session endpoint despite "200" response code'
              )

              return session_creation_result
            else
              return nil
            end
          end

      end
    end
  end
end
