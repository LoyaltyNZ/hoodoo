
module Hoodoo
  module Client
    class Endpoint # Just used as a namespace here

      # An endpoint that, when called, returns 'Not Found' for
      # the resource at hand. Used to emulate lazily resolved
      # endpoints when in fact, the lack of endpoint presence
      # is already known.
      #
      class NotFound < Hoodoo::Client::Endpoint::HTTPBased

        protected

          # See Hoodoo::Client::Endpoint#configure_with.
          #
          def configure_with( resource, version, options )
            super( resource, version, options )
          end

        public

          # See Hoodoo::Client::Endpoint#list.
          #
          def list( query_hash = nil )
            return generate_404_response_for( :list )
          end

          # See Hoodoo::Client::Endpoint#show.
          #
          def show( ident, query_hash = nil )
            return generate_404_response_for( :show )
          end

          # See Hoodoo::Client::Endpoint#create.
          #
          def create( body_hash, query_hash = nil )
            return generate_404_response_for( :create )
          end

          # See Hoodoo::Client::Endpoint#update.
          #
          def update( ident, body_hash, query_hash = nil )
            return generate_404_response_for( :update )
          end

          # See Hoodoo::Client::Endpoint#delete.
          #
          def delete( ident, query_hash = nil )
            return generate_404_response_for( :delete )
          end

      end
    end
  end
end
