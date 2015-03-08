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

      # Base class for endpoints that have an HTTP basis to their request
      # and responses, even if the underlying transport is not HTTP. This
      # is basically a collection of library-like routines useful to such
      # classes and specifically excludes the part which actually makes
      # an HTTP call (or AMQP call, or whatever) to a resource. That's up
      # to the subclass.
      #
      # This must never be instantiated directly as an endpoint. Instead,
      # instantiate a subclass such as Hoodoo::Client::Endpoint::HTTP or
      # Hoodoo::Client::Endpoint::AMQP.
      #
      class HTTPBased < Hoodoo::Client::Endpoint

        protected

          # See Hoodoo::Client::Endpoint#configure_with.
          #
          # Subclass must call "super" to get +@resource+ and +@version+
          # set, then store whatever other information they need about
          # the discovery result data.
          #
          def configure_with( resource, version, discovery_result )
            @resource = resource
            @version  = version
          end

        protected

          class DescriptionOfRequest
            attr_accessor :action

            attr_accessor :discovery_result
            attr_accessor :endpoint_uri
            attr_accessor :body_hash
            attr_accessor :query_hash
            attr_accessor :ident

            attr_accessor :session
            attr_accessor :locale
          end

          class DataForRequest
            attr_accessor :full_uri
            attr_accessor :body_string
            attr_accessor :header_hash
          end

          class DescriptionOfResponse
            attr_accessor :action
            attr_accessor :http_status_code
            attr_accessor :raw_body_data
          end

          def response_class_for( action )
            return action === :list ? Hoodoo::Client::AugmentedArray : Hoodoo::Client::AugmentedHash
          end

          def generate_404_response_for( action )
            data = response_class_for( action ).new
            data.platform_errors.add_error(
              'platform.not_found',
              'reference' => { :entity_name => "v#{ @version } of #{ @resource } interface endpoint" }
            )

            return data
          end

          def get_data_for_request( description_of_request )
            body_hash  = description_of_request.body_hash
            query_hash = description_of_request.query_hash
            ident      = description_of_request.ident
            session    = description_of_request.session

            body_data  = body_hash.nil? ? '' : body_hash.to_json
            remote_uri = description_of_request.endpoint_uri.dup # We will modify this and can't mutate original

            remote_uri.path << "/#{ URI::escape( ident ) }" unless ident.nil?

            # Grey area over whether this encodes spaces as "%20" or "+", but
            # so long as the middleware consistently uses the URI encode/decode
            # calls, it should work out in the end anyway.

            unless query_hash.nil?
              query_hash = query_hash.dup
              query_hash[ 'search' ] = URI.encode_www_form( query_hash[ 'search' ] ) if ( query_hash[ 'search' ].is_a?( ::Hash ) )
              query_hash[ 'filter' ] = URI.encode_www_form( query_hash[ 'filter' ] ) if ( query_hash[ 'filter' ].is_a?( ::Hash ) )

              query_hash[ '_embed'     ] = query_hash[ '_embed'     ].join( ',' ) if ( query_hash[ '_embed'     ].is_a?( ::Array ) )
              query_hash[ '_reference' ] = query_hash[ '_reference' ].join( ',' ) if ( query_hash[ '_reference' ].is_a?( ::Array ) )

              query_hash.delete( 'search'     ) if query_hash[ 'search'     ].nil? || query_hash[ 'search'     ].empty?
              query_hash.delete( 'filter'     ) if query_hash[ 'filter'     ].nil? || query_hash[ 'filter'     ].empty?
              query_hash.delete( '_embed'     ) if query_hash[ '_embed'     ].nil? || query_hash[ '_embed'     ].empty?
              query_hash.delete( '_reference' ) if query_hash[ '_reference' ].nil? || query_hash[ '_reference' ].empty?
            end

            remote_uri.query = URI.encode_www_form( query_hash ) unless query_hash.nil? || query_hash.empty?

            headers = {
              'Content-Type'     => 'application/json; charset=utf-8',
              'Content-Language' => description_of_request.locale || 'en-nz'
            }

            headers[ 'X-Session-ID' ] = session.session_id unless session.nil?

            data             = DataForRequest.new
            data.full_uri    = request_uri
            data.body_string = body_data
            data.header_hash = headers

            return data
          end

          def get_data_for_response( description_of_response )
            code = description_of_response.http_status_code
            body = description_of_response.raw_body_data

            begin
              parsed = JSON.parse( body )
            rescue => e
              data = response_class_for( description_of_response.action ).new

              case code
                when 404
                  return generate_404_response_for( description_of_request.action )
                when 408
                  data.platform_errors.add_error( 'platform.timeout' )
                when 200
                  data.platform_errors.add_error(
                    'platform.fault',
                    :reference => { :exception => RuntimeError.new( 'Could not parse body data returned from inter-resource call despite receiving HTTP status code 200' ) }
                  )
                else
                  data.platform_errors.add_error(
                    'platform.fault',
                    :reference => { :exception => RuntimeError.new( "Unexpected raw HTTP status code #{ code } during inter-resource call" ) }
                  )
              end

              return data
            end

            # Just in case someone changes JSON parsers under us and the
            # replacement doesn't support the options used above...

            unless parsed.is_a?( Hoodoo::Client::AugmentedHash )
              raise "Hoodoo::Services::Middleware: Incompatible JSON implementation in use which doesn't understand 'object_class' or 'array_class' options"
            end

            # If the parsed data wrapped an array, extract just the array
            # part, else the hash part.

            if ( parsed[ '_data' ].is_a?( ::Array ) )
              size   = parsed[ '_dataset_size' ]
              parsed = parsed[ '_data'         ]
              parsed.dataset_size = size

            elsif ( parsed[ 'kind' ] == 'Errors' )

              # This isn't an array, it's an AugmentedHash describing errors.
              # Turn this into a formal errors collection.

              errors_from_resource = Hoodoo::Errors.new()

              parsed[ 'errors' ].each do | error |
                errors_from_resource.add_precompiled_error(
                  error[ 'code'      ],
                  error[ 'message'   ],
                  error[ 'reference' ],
                  code
                )
              end

              # Use a 'clean' copy of the response class rather than keeping
              # the originating data. People will not make assumptions about
              # error payloads and trip over with the early return 404 stuff
              # etc. this way.

              parsed = response_class.new
              parsed.set_platform_errors( errors_from_resource )

              # ! TODO !
              # parsed.set_platform_errors(
              #   translate_errors_from_other_resource( errors_from_resource )
              # )
            end

            return parsed
          end

      end
    end
  end
end
