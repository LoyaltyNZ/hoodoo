########################################################################
# File::    http.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Resource endpoint definition.
# ----------------------------------------------------------------------
#           05-Mar-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Client
    class Endpoint # Just used as a namespace here

      # An endpoint that is contacted over AMQP using HTTP emulation
      # via the Alchemy and AMQ Endpoint gems.
      #
      class AMQP < Hoodoo::Client::Endpoint::HTTPBased

        protected

          # See Hoodoo::Client::Endpoint#configure_with.
          #
          def configure_with( resource, version, options )
            super( resource, version, options )

            discovery_result = options[ :discovery_result ]

            unless discovery_result.is_a?( Hoodoo::Services::Discovery::ForAMQP )
              raise "Hoodoo::Client::Endpoint::AMQP must be configured with a Hoodoo::Services::Discovery::ForAMQP instance - got '#{ discovery_result.class.name }'"
            end

            # Host and port isn't relevant for Alchemy but *is* needed
            # to keep Rack happy.

            endpoint_uri      = URI.parse( 'http://localhost:80' )
            endpoint_uri.path = discovery_result.equivalent_path

            @description                  = Hoodoo::Client::Endpoint::HTTPBased::DescriptionOfRequest.new
            @description.discovery_result = discovery_result
            @description.endpoint_uri     = endpoint_uri
            @description.session          = options[ :session ]
            @description.locale           = options[ :locale  ]
          end

        public

          # See Hoodoo::Client::Endpoint#list.
          #
          def list( query_hash = nil )
            d            = @description.dup
            d.action     = :list
            d.query_hash = query_hash

            return do_amqp( d )
          end

          # See Hoodoo::Client::Endpoint#show.
          #
          def show( ident, query_hash = nil )
            d            = @description.dup
            d.action     = :show
            d.ident      = ident
            d.query_hash = query_hash

            return do_amqp( d )
          end

          # See Hoodoo::Client::Endpoint#create.
          #
          def create( body_hash, query_hash = nil )
            d            = @description.dup
            d.action     = :create
            d.body_hash  = body_hash
            d.query_hash = query_hash

            return do_amqp( d )
          end

          # See Hoodoo::Client::Endpoint#update.
          #
          def update( ident, body_hash, query_hash = nil )
            d            = @description.dup
            d.action     = :update
            d.ident      = ident
            d.body_hash  = body_hash
            d.query_hash = query_hash

            return do_amqp( d )
          end

          # See Hoodoo::Client::Endpoint#delete.
          #
          def delete( ident, query_hash = nil )
            d            = @description.dup
            d.action     = :delete
            d.ident      = ident
            d.query_hash = query_hash

            return do_amqp( d )
          end

        private

          def do_amqp( description_of_request )

            action = description_of_request.action
            data   = get_data_for_request( description_of_request )

            # Host and port are just there to keep Rack happy at the
            # receiving end of the over-AMQP synthesised HTTP request.

            alchemy_options = {
              :host    => description_of_request.endpoint_uri.host,
              :port    => description_of_request.endpoint_uri.port,
              :body    => data.body_string,
              :headers => data.headers
            }

            unless description_of_request.session.nil?
              alchemy_options[ :session_id ] = description_of_requestsession.session_id
            end

            http_method = {
              :create => 'POST',
              :update => 'PATCH',
              :delete => 'DELETE'
            }[ action ] || 'GET'

            description_of_response        = DescriptionOfResponse.new
            description_of_response.action = action

            amqp_response = @@alchemy.http_request(
              description_of_request.discovery_data.queue_name,
              http_method,
              description_of_request.endpoint_uri.path,
              alchemy_options
            )

            description_of_response.http_status_code = amqp_response.status_code
            description_of_response.raw_body_data    = amqp_response.body

            return get_data_for_response( description_of_response )
          end

      end
    end
  end
end
