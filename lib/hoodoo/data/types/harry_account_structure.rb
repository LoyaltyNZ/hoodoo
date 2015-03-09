########################################################################
# File::    harry_account_structure.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Flybuys specific Platform API Type
#           'HarryAccountStructure'.
# ----------------------------------------------------------------------
#           06-March-2015 (CFK): Created.
########################################################################

module Hoodoo
  module Data
    module Types

      #Documented Platform API type: https://github.com/LoyaltyNZ/service_platformification/wiki/Platformification-API
      class HarryAccountStructure < Hoodoo::Presenters::Base

        schema do
          object :account, :required => true do
            resource :Account
          end
          array :members, :required => true do
            resource :Member
          end
          array :tokens, :required => true do
            resource :Token
          end
          array :memberships, :required => true do
            resource :Membership
          end
          array :programmes, :required => true do
            resource :Programme
          end
        end

      end

    end
  end
end