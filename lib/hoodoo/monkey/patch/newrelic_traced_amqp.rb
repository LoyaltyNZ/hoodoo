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

        # Raises LoadError if NewRelic is absent
        #
        require 'newrelic_rpm'
        require 'new_relic/agent/logger'
        require 'new_relic/agent/transaction'

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
            # +http_message+:: Hash describing the message to send. See e.g.
            #                  Hoodoo::Client::Endpoint::AMQP#do_amqp. Note
            #                  that the header names inside this Hash are the
            #                  mixed case, HTTP specification style ones like
            #                  <tt>X-Interaction-ID</tt> and _not_ the Rack
            #                  names like <tt>HTTP_X_INTERACTION_ID</tt>.
            #
            # +full_uri+::     URI being sent to. This is somewhat meaningless
            #                  when using AMQP but NewRelic requires it.
            #
            def monkey_send_request( http_message, full_uri )
              amqp_response   = nil
              wrapped_request = AlchemyFluxHTTPRequestWrapper.new(
                http_message,
                full_uri
              )

              segment = ::NewRelic::Agent::Transaction.start_external_request_segment(
                wrapped_request.type,
                wrapped_request.uri,
                wrapped_request.method
              )

              begin
                segment.add_request_headers( wrapped_request )

                amqp_response = super( http_message, full_uri )

                # The outer block extracts required information from the
                # object returned by this block. Need to wrap it match the
                # expected interface.
                #
                wrapped_response = AlchemyFluxHTTPResponseWrapper.new(
                  amqp_response
                )

                segment.read_response_headers( wrapped_response )

              ensure
                segment.finish()

              end

              return amqp_response
            end
          end

          # Wrapper class for an AMQP request which conforms to the API that
          # NewRelic expects.
          #
          class AlchemyFluxHTTPRequestWrapper

            # Wrap the Alchemy Flux +http_message+ aimed at the specified
            # +full_uri+.
            #
            # +http_message+:: Hash describing the message to send. See e.g.
            #                  Hoodoo::Client::Endpoint::AMQP#do_amqp. Note
            #                  that the header names inside this Hash are the
            #                  mixed case, HTTP specification style ones like
            #                  <tt>X-Interaction-ID</tt> and _not_ the Rack
            #                  names like <tt>HTTP_X_INTERACTION_ID</tt>.
            #
            # +full_uri+::     Full target URI, as a String.
            #
            def initialize( http_message, full_uri )
              @http_message = http_message
              @full_uri     = full_uri
            end

            # String describing what kind of request this is.
            #
            def type
              'AlchemyFlux'
            end

            # String descrbing this request's intended host, according to the
            # +Host+ header. May return +nil+ if none is found.
            #
            # See also: #host.
            #
            def host_from_header
              begin
                @http_message[ 'headers' ][ 'host' ] || @http_message[ 'headers' ][ 'Host' ]
              rescue
                nil
              end
            end

            # String describing this request's intended host.
            #
            # See also: #host_from_header.
            #
            def host
              self.host_from_header() || @http_message[ 'host' ]
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

            # URI object describing the full request URI.
            #
            def uri
              URI.parse( @full_uri.to_s )
            end

          end

          # Wrapper class for an AMQP request which conforms to the API that
          # NewRelic expects.
          #
          class AlchemyFluxHTTPResponseWrapper

            # The +response_hash+ to be wrapped.
            #
            # +response_hash+:: Hash describing the response returned from
            #                   Alchemy Flux. See that gem for details.
            #
            def initialize( response_hash )
              @response_hash = response_hash
            end

            # Look up a key in the headers Hash first, but if absent try the
            # top-level response Hash instead.
            #
            # +key+:: Hash key to look up.
            #
            def []( key )
              @response_hash[ 'headers' ][ key ] || @response_hash[ key ]
            end

            # Return the HTTP headers for this response as a Hash.
            #
            def to_hash
              @response_hash[ 'headers' ].dup()
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
