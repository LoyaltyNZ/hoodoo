########################################################################
# File::    refund.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Platform API Resource 'Refund'.
# ----------------------------------------------------------------------
#           27-Jan-2015 (JML): Created.
#           30-Mar-2015 (JML): Added token_identifier
#           08-Apr-2015 (JML): Made Basket Optional
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Refund'.
      #
      class Refund < Hoodoo::Presenters::Base

        schema do
          object :basket do
            type :Basket
          end

          uuid   :purchase_id,  :required => true, :resource => :Purchase
        end

      end
    end
  end
end
