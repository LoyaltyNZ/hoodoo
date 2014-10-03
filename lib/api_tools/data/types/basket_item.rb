########################################################################
# File::    basket_item.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'BasketItem'.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

# Ruby namespace for the facilities provided by the ApiTools gem.
#
module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'BasketItem'.
      #
      class BasketItem < ApiTools::Data::DocumentedPresenter

        schema do
          integer :quantity, :required => true

          object :currency_amount, :required => true do
            type :CurrencyAmount
          end

          uuid :product_id, :resource => :Product
          text :product_code

          object :product_data do
            type :Product
          end

          enum :accrual, :from => [ :excluded ]
        end

      end
    end
  end
end
