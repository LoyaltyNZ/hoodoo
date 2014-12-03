########################################################################
# File::    member.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Member'.
# ----------------------------------------------------------------------
#           07-Nov-2014 (DAM): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Member'.
      #
      class Member < ApiTools::Presenters::Base

        schema do
          internationalised

          uuid :account_id,    :resource => Account
          text :informal_name
          text :formal_name,   :required => true
          date :date_of_birth, :required => true
        end

      end
    end
  end
end
