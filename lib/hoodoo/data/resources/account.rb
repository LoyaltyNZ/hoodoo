########################################################################
# File::    account.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Account'.
# ----------------------------------------------------------------------
#           07-Nov-2014 (DAM): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      #  Since Member references Account and Account references Member, we have
      #  to define a dummy Member class here and ensure that the below
      #  ordering in hoodoo.rb is maintained (account before member)
      #
      # require root+'data/resources/account.rb'
      # require root+'data/resources/member.rb'
      #
      class Member < Hoodoo::Presenters::Base
      end

      # Documented Platform API Resource 'Account'.
      #
      class Account < Hoodoo::Presenters::Base
        schema do
        end
      end
    end
  end
end
