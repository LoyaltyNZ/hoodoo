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



      def acquire_session
        # TODO
        # post to Session with client ID and secret else return error
        return Hoodoo::Services::Middleware.test_session()
      end

  end
end
