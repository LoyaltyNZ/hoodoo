########################################################################
# File::    platformify_event.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Flybuys specific Platform API Resource 'PlatformifyEvent'.
# ----------------------------------------------------------------------
#           06-Mar-2015 (CFK): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      #Documented Platform API resource: https://github.com/LoyaltyNZ/service_platformification/wiki/Platformification-API
      class PlatformifyEvent < Hoodoo::Presenters::Base

        schema do
          text :token_identifier, :required => true
          uuid :sync_platformify_event_id, :required => true , resource: :SyncPlatformifyEvent
        end
      end

    end
  end
end