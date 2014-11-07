########################################################################
# File::    token.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Token'.
# ----------------------------------------------------------------------
#           07-Nov-2014 (DAM): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Token'.
      #
      class Token < ApiTools::Data::DocumentedPresenter

        schema do
          enum :state,      :from     => [:waiting, :active, :closed]
          text :identifier, :required => true
          uuid :member_id,  :required => true, :resource => Member
        end

      end
    end
  end
end
