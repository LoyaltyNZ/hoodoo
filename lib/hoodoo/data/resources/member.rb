########################################################################
# File::    member.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Member'.
# ----------------------------------------------------------------------
#           07-Nov-2014 (DAM): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Member'.
      #
      class Member < Hoodoo::Presenters::Base

        schema do
          uuid :account_id,    :resource => :Account
        end

      end
    end
  end
end
