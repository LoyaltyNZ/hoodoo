########################################################################
# File::    purchase.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Purchase'.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
#           19-Nov-2014 (ADH): Updated in light of Preview Release 11
#                              specification changes.
#           14-Jul-2015 (JML): Added backdated_to field
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Purchase'.
      #
      class Purchase < Hoodoo::Presenters::Base

        schema do
          text      :token_identifier
          datetime  :backdated_to

          object :basket, :required => true do
            type :Basket
          end

          text      :pos_reference
          uuid      :estimation_id, :resource => :Estimation
        end

      end
    end
  end
end
