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
      class Member < ApiTools::Data::DocumentedPresenter

        schema do
          internationalised

          uuid :account_id,    :resource => Account, :required => true
          text :formal_name,   :required => true
          text :informal_name
          date :date_of_birth, :required => true
        end

      end
    end
  end
end
