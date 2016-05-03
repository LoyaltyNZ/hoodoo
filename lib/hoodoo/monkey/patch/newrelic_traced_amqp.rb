########################################################################
# File::    newrelic_traced_amqp.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Extend the AMQP endpoint to support NewRelic cross-app
#           transaction tracing. Only defined and registered if the
#           NewRelic gem is available and Hoodooo Client is in scope.
#
#           See Hoodoo::Monkey::Patch::NewRelicTracedAMQP for more.
# ----------------------------------------------------------------------
#           08-Apr-2016 (RJS): Created.
########################################################################

module Hoodoo
  module Monkey
    module Patch

      begin
        require 'newrelic_rpm' # Raises LoadError if NewRelic is absent

        # Wrap Hoodoo::Client::Endpoint::AMQP using NewRelic transaction
        # tracing so that over-queue inter-resource calls get connected
        # together in NewRelic's view of the world.
        #
        # This module self-registers with Hooodoo::Monkey and, provided
        # that Hoodoo::Services::Middleware is defined at parse-time,
        # will be enabled by default.
        #
        module NewRelicTracedAMQP

          # Instance methods to patch over Hoodoo::Client::Endpoint::AMQP.
          #
          module InstanceExtensions

            # Wrap the request with NewRelic's cross-app transaction tracing.
            # This adds headers to the request and extracts header data from
            # the response. It calls the original implementation via +super+.
            #
            # +http_message+:: Hash describing the message to send.
            #
            # +full_uri+::     URI being sent to. This is somewhat meaningless
            #                  when using AMQP but NewRelic requires it.
            #
            def monkey_send_request( http_message, full_uri )
              amqp_response    = nil
              newrelic_request = ::Hoodoo::Monkey::Patch::NewRelicTracedAMQP::AMQPNewRelicRequestWrapper.new(
                http_message,
                full_uri
              )

              ::NewRelic::Agent::CrossAppTracing.tl_trace_http_request( newrelic_request ) do

                # Disable further tracing in request to avoid double counting
                # if connection wasn't started (which calls request again).
                #
                ::NewRelic::Agent.disable_all_tracing do

                  amqp_response = super( http_message, full_uri )

                  # The outer block extracts required information from the
                  # object returned by this block. Need to wrap it match the
                  # expected interface.
                  #
                  ::Hoodoo::Monkey::Patch::NewRelicTracedAMQP::AMQPNewRelicResponseWrapper.new(
                    amqp_response
                  )

                end
              end

              return amqp_response
            end
          end

          # Wrapper class for an AMQP request which conforms to the API that
          # NewRelic expects.
          #
          class AMQPNewRelicRequestWrapper

            # Wrap the Alchemy Flux +http_message+ aimed at the specified
            # +full_uri+.
            #
            # +http_message+:: Hash describing the request for Alchemy Flux.
            # +full_uri+::     Full target URI, as a String.
            #
            def initialize( http_message, full_uri )
              @http_message = http_message
              @full_uri     = full_uri
            end

            # String describing what kind of request this is.
            #
            def type
              self.class.to_s()
            end

            # String describing this request's intended host.
            #
            def host
              @http_message[ 'host' ]
            end

            # String describing this request's HTTP verb (GET, POST and
            # so-on). String case is undefined, so perform case-insensitive
            # comparisions.
            #
            def method
              @http_message[ 'verb' ]
            end

            # Key lookup is delegated to the headers Hash per NewRelic's
            # expectations of how a request behaves.
            #
            # +key+:: Hash key to look up.
            #
            def []( key )
              @http_message[ 'headers' ][ key ]
            end

            # Key setting is delegated to the headers Hash per NewRelic's
            # expectations of how a request behaves.
            #
            # +key+::   Key of Hash entry to modify.
            # +value+:: New or replacement value for identified Hash entry.
            #
            def []=( key, value )
              @http_message[ 'headers' ][ key ] = value
            end

            # String describing the full request URI.
            #
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
            # +response_hash+:: Hash describing the response returned from
            #                   Alchemy Flux.
            #
            def initialize( response_hash )
              @response_hash = response_hash
            end

            # If the NewRelic cross-app tracing header is the +key+, return the
            # value of the header that matches that key. Otherwise look up the
            # key like normal.
            #
            # +key+:: Hash key to look up.
            #
            def []( key )
              if key == ::NewRelic::Agent::CrossAppTracing::NR_APPDATA_HEADER
                @response_hash[ 'headers' ][ key ]
              else
                @response_hash[ key ]
              end
            end
          end
        end

        # Register this class with the Hoodoo monkey patch engine.
        #
        if defined?( Hoodoo::Client ) &&
           defined?( Hoodoo::Client::Endpoint ) &&
           defined?( Hoodoo::Client::Endpoint::AMQP )

          Hoodoo::Monkey.register(
            target_unit:      Hoodoo::Client::Endpoint::AMQP,
            extension_module: Hoodoo::Monkey::Patch::NewRelicTracedAMQP
          )

          if defined?( Hoodoo::Services ) &&
             defined?( Hoodoo::Services::Middleware )

            Hoodoo::Monkey.enable( extension_module: Hoodoo::Monkey::Patch::NewRelicTracedAMQP )
          end
        end

      rescue LoadError
        # No NewRelic => do nothing
      end

    end # module Patch
  end   # module Monkey
end     # module Hoodoo
