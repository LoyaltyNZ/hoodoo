########################################################################
# File::    product.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Outlet'.
# ----------------------------------------------------------------------
#           29-Oct-2014 (JML): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Outlet'.
      #
      class Outlet < Hoodoo::Presenters::Base

        schema do
          internationalised

          text :name
          uuid :participant_id, :resource => :Participant, :required => true
        end

      end
    end
  end
end
