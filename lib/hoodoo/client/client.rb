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
            @discoverer = Hoodoo::Services::Discovery::ByConvention.new(
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



          So Endpoint gets given a Discoverer? But how can it deal with the results?
          It doesn't, those go to IRLocal or IRRemote


          Refactor discovery out to some kind of Discovery hierarchy?

          So you ask for endpoint talk to it get 404
          Discovery via:
          Preconfigured URL (that's what this code would use)
          DRb (Middleware would use it, after checking local)
          Queue (Middleware would use it, after checking local)
          Something else
          Middleware ought to have defaults but allow external discovery specification
          '




        end

      private

        def acquire_session
          post to Session with client ID and secret else return error
        end

    end
  end
end
