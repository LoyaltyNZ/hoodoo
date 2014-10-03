########################################################################
# File::    purchase.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Purchase'.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

# Ruby namespace for the facilities provided by the ApiTools gem.
#
module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Purchase'.
      #
      class Purchase < ApiTools::Data::DocumentedPresenter

        schema do
          text :token_identifier

          object :basket, :required => true do
            type :Basket
          end

          text :pos_reference
          uuid :estimation_id, :resource => :Estimation
          uuid :promotion_id, :resource => :Promotion, :required => true
        end

      end
    end
  end
end
