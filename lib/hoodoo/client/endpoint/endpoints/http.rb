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

      # Used by Hoodoo::Service::Context to encapsulate information
      # needed for an inter-resource call from one resource
      # implementation to another. From the caller's perspective,
      # the operation looks the same whether the target resource is
      # in the same application or another application and if so, the
      # transport (e.g. HTTP, AMQP) is irrelevant to the caller too.
      #
      class HTTP < Hoodoo::Client::Endpoint::HTTPBased

        protected

          # See Hoodoo::Client::Endpoint#configure_with.
          #
          def configure_with( resource, version, options )
            super( resource, version, options )

            discovery_result = options[ :discovery_result ]

            unless discovery_result.is_a?( Hoodoo::Services::Discovery::ForHTTP )
              raise "Hoodoo::Client::Endpoint::HTTP must be configured with a Hoodoo::Services::Discovery::ForHTTP instance - got '#{ discovery_result.class.name }'"
            end

            @description                  = Hoodoo::Client::Endpoint::HTTPBased::DescriptionOfRequest.new
            @description.discovery_result = discovery_result
            @description.endpoint_uri     = discovery_result.endpoint_uri
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

            return do_http( d )
          end

          # See Hoodoo::Client::Endpoint#show.
          #
          def show( ident, query_hash = nil )
            d            = @description.dup
            d.action     = :show
            d.ident      = ident
            d.query_hash = query_hash

            return do_http( d )
          end

          # See Hoodoo::Client::Endpoint#create.
          #
          def create( body_hash, query_hash = nil )
            d            = @description.dup
            d.action     = :create
            d.body_hash  = body_hash
            d.query_hash = query_hash

            return do_http( d )
          end

          # See Hoodoo::Client::Endpoint#update.
          #
          def update( ident, body_hash, query_hash = nil )
            d            = @description.dup
            d.action     = :update
            d.ident      = ident
            d.body_hash  = body_hash
            d.query_hash = query_hash

            return do_http( d )
          end

          # See Hoodoo::Client::Endpoint#delete.
          #
          def delete( ident, query_hash = nil )
            d            = @description.dup
            d.action     = :delete
            d.ident      = ident
            d.query_hash = query_hash

            return do_http( d )
          end

        private

          def do_http( description_of_request )

            action = description_of_request.action
            data   = get_data_for_request( description_of_request )

            if data.full_uri.scheme == "https"
              http.use_ssl = true

              # TODO:  Urgent
              # FIXME: Urgent
              #
              http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            end

            request_class = {
              :create => Net::HTTP::Post,
              :update => Net::HTTP::Patch,
              :delete => Net::HTTP::Delete
            }[ action ] || Net::HTTP::Get

            request      = request_class.new( remote_uri.request_uri() )
            request.body = data.body_string unless data.body_string.empty?

            request.initialize_http_header( data.headers )

            description_of_response        = DescriptionOfResponse.new
            description_of_response.action = action

            begin
              http_response = http.request( request )

              description_of_response.http_status_code = http_response.code
              description_of_response.raw_body_data    = http_response.body

            rescue Errno::ECONNREFUSED => e
              description_of_response.http_status_code = 404
              description_of_response.raw_body_data    = ''

            end

            return get_data_for_response( description_of_response )
          end


      end
    end
  end
end
