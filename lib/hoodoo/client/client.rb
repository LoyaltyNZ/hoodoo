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
                        caller_secret: nil )

          @platform_uri  = platform_uri
          @drb_port      = drb_port
          @caller_id     = caller_id
          @caller_secret = caller_secret

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

        def endpoint( resource, version )
          @endpoints[ "#{ resource_name }/#{ version }" ] ||= Hoodoo::Services::Middleware::Endpoint.new(
            self.owning_interaction,
            resource_name,
            version
          )
        end

      private

        def acquire_session
          post to Session with client ID and secret else return error
        end

    end
  end
end