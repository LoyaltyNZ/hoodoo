########################################################################
# File::    http.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Resource endpoint definition.
# ----------------------------------------------------------------------
#           05-Mar-2015 (ADH): Created.
########################################################################

require 'net/http'
require 'net/https'

module Hoodoo
  class Client     # Just used as a namespace here
    class Endpoint # Just used as a namespace here

      # Talk to a resource that is contacted over HTTP or HTTPS.
      #
      # Configured with a Hoodoo::Services::Discovery::ForHTTP discovery
      # result instance.
      #
      class HTTP < Hoodoo::Client::Endpoint::HTTPBased

        protected

          # See Hoodoo::Client::Endpoint#configure_with.
          #
          # Requires a Hoodoo::Services::Discovery::ForHTTP instance in the
          # +discovery_result+ field of the +options+ Hash.
          #
          def configure_with( resource, version, options )
            unless @discovery_result.is_a?( Hoodoo::Services::Discovery::ForHTTP )
              raise "Hoodoo::Client::Endpoint::HTTP must be configured with a Hoodoo::Services::Discovery::ForHTTP instance - got '#{ @discovery_result.class.name }'"
            end

            @description                   = Hoodoo::Client::Endpoint::HTTPBased::DescriptionOfRequest.new
            @description.discovery_result  = @discovery_result
            @description.endpoint_uri      = @discovery_result.endpoint_uri
            @description.proxy_uri         = @discovery_result.proxy_uri
            @description.ca_file           = @discovery_result.ca_file
            @description.http_timeout      = @discovery_result.http_timeout
            @description.http_open_timeout = @discovery_result.http_open_timeout
          end

        public

          # See Hoodoo::Client::Endpoint#list.
          #
          def list( query_hash = nil )
            d            = @description.dup # This does NOT dup the objects to which @description points
            d.action     = :list
            d.query_hash = query_hash

            return inject_enumeration_state( do_http( d ), query_hash )
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

          # Make real HTTP(S) request to a target resource and return the
          # result as a Hoodoo::Client::AugmentedArray (for 'list' calls) or
          # Hoodoo::Client::AugumentedHash (for all other calls) instance.
          #
          # +description_of_request+:: A Hoodoo::Client::Endpoint::HTTPBased::DescriptionOfRequest
          #                            instance with all the request details
          #                            set inside. The +discovery_data+ field
          #                            must refer to a
          #                            Hoodoo::Services::Discovery::ForHTTP
          #                            instance (not re-checked internally).
          #
          def do_http( description_of_request )

            data = get_data_for_request( description_of_request )

            action            = description_of_request.action
            proxy             = description_of_request.proxy_uri
            ca_file           = description_of_request.ca_file
            http_timeout      = description_of_request.http_timeout
            http_open_timeout = description_of_request.http_open_timeout

            proxy_host = :ENV
            proxy_port = proxy_user = proxy_pass = nil

            unless proxy.nil?
              proxy_host = proxy.host
              proxy_port = proxy.port
              proxy_user = proxy.user
              proxy_pass = proxy.password
            end

            http = Net::HTTP.new(
              data.full_uri.host,
              data.full_uri.port,
              proxy_host,
              proxy_port,
              proxy_user,
              proxy_pass
            )

            if data.full_uri.scheme == 'https'
              http.use_ssl = true

              # The verify_mode is *important* - VERIFY_PEER ensures that we always validate
              # the connection, *and* that the presented SSL Certificate by the endpoint is
              # verifiable through our CA certificate trust store.
              #
              # To use a self-signed cert, you may configure the ca_file to a CA that
              # includes the self-signed cert, but the verify_mode setting should remain.
              #
              http.verify_mode = OpenSSL::SSL::VERIFY_PEER

              if ca_file
                http.ca_file = ca_file
              end
            end

            http.read_timeout = http_timeout unless http_timeout.nil?
            http.open_timeout = http_open_timeout unless http_open_timeout.nil?

            request_class = {
              :create => Net::HTTP::Post,
              :update => Net::HTTP::Patch,
              :delete => Net::HTTP::Delete
            }[ action ] || Net::HTTP::Get

            request      = request_class.new( data.full_uri.request_uri() )
            request.body = data.body_string unless data.body_string.empty?

            request.initialize_http_header( data.header_hash )

            description_of_response              = DescriptionOfResponse.new
            description_of_response.action       = action
            description_of_response.http_headers = {}

            begin

              http_response = http.request( request )

              description_of_response.http_status_code = http_response.code.to_i
              description_of_response.http_headers     = http_response
              description_of_response.raw_body_data    = http_response.body

            rescue Errno::ECONNREFUSED => e
              description_of_response.http_status_code = 404
              description_of_response.raw_body_data    = ''

            rescue Net::ReadTimeout, Net::OpenTimeout => e
              description_of_response.http_status_code = 408
              description_of_response.raw_body_data    = ''

            rescue => e
              description_of_response.http_status_code = 500
              description_of_response.raw_body_data    = e.message

            end

            return get_data_for_response( description_of_response )
          end

      end
    end
  end
end
