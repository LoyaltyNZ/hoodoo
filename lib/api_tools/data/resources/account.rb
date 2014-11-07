########################################################################
# File::    account.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Account'.
# ----------------------------------------------------------------------
#           07-Nov-2014 (DAM): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      ########################################################################
      # Woooooo, whats going on here............
      #  Since Member references Account and Account references Member, we have
      #  to define a dummy Member class here and ensure that the below
      #  ordering in api_tools.rb is maintained (account before member)
      #
      # require root+'data/resources/account.rb'
      # require root+'data/resources/member.rb'
      #
      ########################################################################
      class Member < ApiTools::Data::DocumentedPresenter
      end

      # Documented Platform API Resource 'Account'.
      #
      class Account < ApiTools::Data::DocumentedPresenter
        schema do
          uuid :owner_id, resource: Member
        end

      end
    end
  end
end
