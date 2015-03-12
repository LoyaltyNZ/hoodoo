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

  class Client

    public

      def initialize( platform_uri:          nil,
                      drb_port:              nil,

                      locale:                nil,

                      session:               nil,
                      auto_session:          :true,
                      auto_session_resource: 'Session',
                      auto_session_version:  1,
                      caller_id:             nil,
                      caller_secret:         nil )

        @endpoints     = {}
        @platform_uri  = platform_uri
        @drb_port      = drb_port

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

        # If doing automatic sessions, acquire a session creation endpoint

        @session_id    = session.session_id unless session.nil?
        @caller_id     = caller_id
        @caller_secret = caller_secret

        if auto_session
          @auto_session_endpoint = Hoodoo::Client::Endpoint.endpoint_for(
            auto_session_resource,
            auto_session_version,
            { :discoverer => @discoverer }
          )
        end
      end

      def resource( resource, version )
        resource = resource.to_sym
        version  = version.to_i

        @endpoints[ resource ] ||= {}

        endpoint = @endpoints[ resource ][ version ]
        return endpoint unless endpoint.nil?

        endpoint = Hoodoo::Client::Endpoint.endpoint_for(
          resource,
          version,
          {
            :discoverer => @discoverer,
            :session_id => @session_id,
            :locale     => @locale
          }
        )

        unless @auto_session_endpoint.nil?
          remote_discovery_result = Hoodoo::Services::Discovery::ForRemote.new(
            :resource         => resource,
            :version          => version,
            :wrapped_endpoint => endpoint
          )

          endpoint = Hoodoo::Client::Endpoint::AutoSession.new(
            resource,
            version,
            :caller_id => @caller_id,
            :caller_secret => @caller_secret,
            :session_endpoint => @auto_session_endpoint,
            :discovery_result => remote_discovery_result
          )
        end

        @endpoints[ resource ][ version ] = endpoint
        return endpoint
      end

  end
end
