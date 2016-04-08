########################################################################
# File::    new_relic_traced_amqp.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Extend the AMQP endpoint to support NewRelic cross-app
#           transaction tracing.
# ----------------------------------------------------------------------
#           08-Apr-2016 (RJS): Created.
########################################################################

module Hoodoo
  class Client     # Just used as a namespace here
    class Endpoint # Just used as a namespace here

      if defined?( NewRelic )

        # Extend the AMQP endpoint to support New Relic cross-app transaction
        # traces.
        #
        class AMQP < Hoodoo::Client::Endpoint::HTTPBased

          private

            # Wrap the request with NewRelic's cross-app transaction tracing.
            # This will add headers to the request and extract header data from
            # the response.
            #
            def send_request_with_new_relic_trace( http_message )
              new_relic_request = Hoodoo::Client::Endpoint::AMQPNewRelicRequestWrapper.new(
                http_message,
                data.full_uri
              )

              amqp_response = nil
              ::NewRelic::Agent::CrossAppTracing.tl_trace_http_request( new_relic_request ) do
                # Disable further tracing in request to avoid double counting if
                # connection wasn't started (which calls request again).
                ::NewRelic::Agent.disable_all_tracing do
                  amqp_response = send_request_without_new_relic_trace( http_message )

                  # The outer block extracts required information from the object
                  # returned by this block. Need to wrap it match the expected
                  # interface.
                  #
                  Hoodoo::Client::Endpoint::AMQPNewRelicResponseWrapper.new(
                    amqp_response
                  )
                end
              end

              return amqp_response
            end

            alias send_request_without_newrelic_trace send_request
            alias send_request send_request_with_newrelic_trace

        end

        # Wrapper class for an AMQP request which conforms to the API that
        # NewRelic expects.
        #
        class AMQPNewRelicRequestWrapper

          # Wrap the +http_message+ to the specified +full_uri+.
          #
          # +http_message+:: Hash describing the request.
          #
          # +full_uri+::     Target URI.
          #
          def initialize( http_message, full_uri )
            @http_message = http_message
            @full_uri     = full_uri
          end

          # String describing what kind of request this is.
          def type
            'Hoodoo::Client::Endpoint::AMQPNewRelicWrapper'
          end

          def host
            @http_message[ 'host' ]
          end

          def method
            @http_message[ 'verb' ]
          end

          # Key lookup is delegated to the headers Hash per NewRelic's
          # expectations of how a request behaves.
          #
          def [](key)
            @http_message[ 'headers' ][ key ]
          end

          # Key setting is delegated to the headers Hash per NewRelic's
          # expectations of how a request behaves.
          #
          def []=(key, value)
            @http_message[ 'headers' ][ key ] = value
          end

          def uri
            @full_uri
          end

        end

        # Wrapper class for an AMQP request which conforms to the API that
        # NewRelic expects.
        #
        class AMQPNewRelicResponseWrapper

          # The +response_hash+ to be wrapped.
          #
          # +response_hash+:: Hash describing the response as returned from
          # Alchemy.
          #
          def initialize( response_hash )
            @response_hash = response_hash
          end

          # If the NewRelic cross-app tracing header is the +key+, return the
          # value of the header that matches that key. Otherwise look up the
          # key like normal.
          #
          def [](key)
            if key == NewRelic::Agent::CrossAppTracing::NR_APPDATA_HEADER
              @response_hash[ 'headers' ][ key ]
            else
              @response_hash[ key ]
            end
          end

        end

      end
    end
  end
end
