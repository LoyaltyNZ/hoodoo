########################################################################
# File::    http_based.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Resource endpoint definition.
# ----------------------------------------------------------------------
#           05-Mar-2015 (ADH): Created.
########################################################################

require 'json'

module Hoodoo
  class Client     # Just used as a namespace here
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

          # Describe a request for HTTP-like endpoints.
          #
          class DescriptionOfRequest

            # The action to perform - a Symbol from
            # Hoodoo::Services::Middleware::ALLOWED_ACTIONS.
            #
            attr_accessor :action

            # A Hoodoo::Services::Discovery "For..." family member instance
            # giving information required to 'find' the target resource. The
            # required class instance depends upon the endpoint in use.
            #
            attr_accessor :discovery_result

            # The full HTTP URI (or equivalent HTTP URI for HTTP-like, but
            # non-HTTP systems like AMQP) at which the endpoint is found.
            # Excludes any query string or resource identifier portion (it
            # is the "list" action URI without query data, in essence)
            #
            attr_accessor :endpoint_uri

            # Full URI (as a URI object) of an HTTP proxy to use as an
            # override to <tt>ENV['HTTP_PROXY']</tt> which Ruby itself
            # will otherwise read. Will be +nil+ for no proxy override.
            #
            attr_accessor :proxy_uri

            # An optional String indicating a relative or absolute file
            # path to the location of a .pem format Certificate
            # Authority file (trust store), which may include multliple
            # certificates. The certificates in the file will be used
            # by Net::HTTP to validate the SSL Ceritificate Chain
            # presented by remote servers, when calling endpoints over
            # HTTPS with Hoodoo::Client.
            #
            # Default +nil+ value should be used in nearly all cases
            # and uses Ruby OpenSSL defaults which are generally
            # Operating System provided.
            #
            attr_accessor :ca_file

            # Optional Hash of query data.
            #
            attr_accessor :query_hash

            # Optional Hash of body data for actions +:create+ and +:update+.
            #
            attr_accessor :body_hash

            # Optional resource identifier for actions +:show+, +:update+ and
            # +:delete+:
            #
            attr_accessor :ident

          end

          # Description of data that will be used for request - essentially a
          # compilation of a DescriptionOfRequest instance produced via a call
          # to #get_data_for_request.
          #
          class DataForRequest

            # The full HTTP URI (or equivalent HTTP URI for HTTP-like, but
            # non-HTTP systems like AMQP) for the call, including any resource
            # identifier and query data.
            #
            attr_accessor :full_uri

            # String of compiled body data for all actions (may be empty).
            #
            attr_accessor :body_string

            # Hash of headers; keys are HTTP header names as a Strings (e.g.
            # "Content-Type", "X-Interaction-ID"), values are header values
            # as Strings.
            #
            attr_accessor :header_hash

            # Hash of query; keys are query keys as Strings (e.g.
            # "search"), values are query values as URL encoded Strings. (e.g.
            # "outlet_id%3Dd32a0e15754a486989fdde2b0830fe12")
            #
            attr_accessor :query_hash

          end

          # Description of data describing an HTTP response. Used by
          # #get_data_for_response to generate a response array or hash
          # (see #response_class_for).
          #
          class DescriptionOfResponse

            # The action that was performed - a Symbol from
            # Hoodoo::Services::Middleware::ALLOWED_ACTIONS.
            #
            attr_accessor :action

            # The HTTP status code _as an Integer_.
            #
            attr_accessor :http_status_code

            # The raw ("unparsed") returned body data as a String.
            #
            attr_accessor :raw_body_data

          end

          # Preprocess a high level request description, returning HTTP
          # orientated compiled data as a DataForRequest instance.
          #
          # +description_of_request+:: DescriptionOfRequest instance.
          #
          def get_data_for_request( description_of_request )
            body_hash  = Hoodoo::Utilities.stringify( description_of_request.body_hash  )
            query_hash = Hoodoo::Utilities.stringify( description_of_request.query_hash )
            ident      = description_of_request.ident.to_s

            body_data  = body_hash.nil? ? '' : ::JSON.generate( body_hash )

            # Amazingly, there's no fast way to deep clone a URI. Long story
            # short - Marshal.load(Marshal.dump(uri)) takes, astonishingly,
            # twice as long to execute as URI.parse(uri.to_s). I have no idea
            # how that's possible. The Addressable gem is even slower.
            #
            #   require 'benchmark'
            #   require 'addressable/uri' # Assuming gem is present
            #
            #   s='http://user:password@pond.org.uk:9924/foo/bar.baz?thing=that'
            #   u=URI.parse(s)
            #   a=Addressable::URI.parse(s)
            #
            #   Benchmark.realtime { 1000000.times { u2=URI.parse(u.to_s) } }
            #   # => 14.110195
            #   Benchmark.realtime { 1000000.times { a2=a.dup } }
            #   # => 26.530487
            #   Benchmark.realtime { 1000000.times { u2=Marshal.load(Marshal.dump(u)) } }
            #   # => 22.048637
            #
            # ...repeatably.
            #
            # TODO: Is it possible to improve this? It's truly awful, to the
            #       extent I'm almost motivated to write a URI handler gem.
            #       The core library URI API is tragically bad.

            remote_uri = URI.parse( description_of_request.endpoint_uri.to_s )

            # Now we've a copy, we can use high level URI methods to manipulate
            # it to form the full request URI.

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
              'Content-Language' => self.locale() || 'en-nz', # Locale comes from Endpoint superclass
              'Accept-Language'  => self.locale() || 'en-nz'
            }

            # Interaction comes from Endpoint superclass.
            #
            # TODO: Can anything be done about inbound X-Interaction-ID
            #       headers or interaction ID values specified by the
            #       calling client which would be stripped by an Alchemy
            #       architecture but not by conventional HTTP servers?
            #
            unless self.interaction().nil?
              headers[ 'X-Interaction-ID' ] = self.interaction().interaction_id
            end

            # Session ID comes from Endpoint superclass.
            #
            unless self.session_id().nil?
              headers[ 'X-Session-ID'] = self.session_id()
            end

            # A suite of options is defined by a constant in the Endpoint
            # superclass.
            #
            HEADER_TO_PROPERTY.each do | rack_header, description |
              header_name = description[ :header      ]
              header_proc = description[ :header_proc ]
              property    = description[ :property    ]

              property_value = self.send( property )

              unless property_value.nil?
                headers[ header_name ] = header_proc.call( property_value )
              end
            end

            data             = DataForRequest.new
            data.full_uri    = remote_uri
            data.body_string = body_data
            data.header_hash = headers
            data.query_hash  = query_hash

            return data
          end

          # Process a raw HTTP response description, returning an instance of
          # Hoodoo::Client::AugmentedArray or Hoodoo::Client::AugmentedHash
          # with either processed body data inside, or error data associated.
          #
          # +description_of_response+:: DescriptionOfResponse instance.
          #
          def get_data_for_response( description_of_response )
            code = description_of_response.http_status_code
            body = description_of_response.raw_body_data

            begin
              parsed = ::JSON.parse(
                body,
                :object_class => Hoodoo::Client::AugmentedHash,
                :array_class  => Hoodoo::Client::AugmentedArray
              )

            rescue => e
              data = response_class_for( description_of_response.action ).new

              case code
                when 404
                  return generate_404_response_for( description_of_response.action )
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
                    :reference => { :exception => RuntimeError.new( "Unexpected raw HTTP status code #{ code } with non-JSON response - #{ body }" ) }
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

              parsed = response_class_for( description_of_response.action ).new
              parsed.set_platform_errors( errors_from_resource )

            end

            return parsed
          end

      end
    end
  end
end
