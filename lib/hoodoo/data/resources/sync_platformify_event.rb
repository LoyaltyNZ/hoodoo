########################################################################
# File::    sync_platformify_event.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Flybuys specific Platform API Resource 'SyncPlatformifyEvent'.
# ----------------------------------------------------------------------
#           06-Mar-2015 (CFK): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      #Documented Platform API resource: https://github.com/LoyaltyNZ/service_platformification/wiki/Platformification-API
      class SyncPlatformifyEvent < Hoodoo::Presenters::Base

        schema do
          object :harry_account_structure, :required => true do
            type :HarryAccountStructure
          end
          object :platform_sync_ids, :required => true do
            uuid :account, :required => true
            array :members, :required => true
            array :tokens, :required => true
            array :memberships, :required => true
            array :programmes, :required => true
          end
        end

      end
    end
  end
end