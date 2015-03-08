########################################################################
# File::    client.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Let people talk to Hoodoo resource endpoints from outside
#           as easily as resource endpoints can talk to one another.
# ----------------------------------------------------------------------
#           25-Feb-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Services

    class Client

      public

        def initialize( platform_uri:,
                        drb_port:,
                        caller_id:     nil,
                        caller_secret: nil,
                        locale:        nil,
                        session:       nil )

          @endpoints     = {}
          @platform_uri  = platform_uri
          @drb_port      = drb_port

          @caller_id     = caller_id
          @caller_secret = caller_secret

          @session       = session
          @locale        = locale

          if @platform_uri != nil
            @discoverer = Hoodoo::Services::Discovery::ByConvention.new(
              :base_uri => @platform_uri
            )
          elsif @drb_port != nil
            @discoverer = Hoodoo::Services::Discovery::ByDRb.new(
              :drb_port => @drb_port
            )
          end

          if @discoverer.nil?
            raise 'No service discovery mechanism selected. Please pass one of the "platform_uri" or "drb_port" parameters.'
          end
        end

        def resource( resource, version )
          return @endpoints[ "#{ resource_name }/#{ version }" ] ||= Hoodoo::Client::Endpoint.endpoint_for(
            resource,
            version,
            {
              :discoverer => @discoverer,
              :session    => self.session,
              :locale     => @locale
            }
          )
        end

      private

        def session
          @session ||= self.acquire_session()
        end



        Some kind of wrapper around resource endpoint calls needed:

        (1) make a call noted as 'not a retry'
        (2) get a 401
        (3) acquire_session:
            - complain if no ID and Secret
            - find Session endpoint
            - Create Session
            - Any non-2xx response, report the session result directly
        (4) Assuming have session, make a call noted as 'is a retry'
        (5) Always return that result without retrying

        Problems:

        (1) The Endpoint is the thing that takes the "list" etc. call,
            so auto session management is impossible unless the endpoint
            did it (and that isn't an endpoint's job)
        (2) No queue/wrapper/whatever writte to manage that behaviour

        So perhaps Client returns _another_ object which is a "wrapped
        endpoint" which does session management, iff it gets a client ID
        and secret (doing away with an "if" elsewhere).

        In that case inter-resource call involves Context returning its
        own kind of wrapping around the endpoint in that it still goes
        back into the middleware (the flow is ugly but ain't broke,
        don't fix). So:

        (1) Context gets '.resource', returns its own Wrapped Endpoint
            - or we could just make "inter_resource.rb" official
            - but really that's bugger all to do with client so it
              doesn't really naturally live there.
        (2) The wrapped endpoint takes a source interaction as before
            and calls back into the middleware
        (3) The middleware determines local or remote resource
        (4) Creates its own AQMP or HTTP endpoint if necessary and
            repeats the inter_resource_remote(foo) stuff to it

        Downsides with (4) is that this is quite a lot of dup stuff
        which feels rather boilerplate. The list of what the
        middleware needs to do extra is in the other text file.



        def acquire_session
          # TODO
          # post to Session with client ID and secret else return error
          return Hoodoo::Services::Middleware.test_session()
        end

    end
  end
end
