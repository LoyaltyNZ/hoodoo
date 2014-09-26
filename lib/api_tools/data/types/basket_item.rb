########################################################################
# File::    basket_item.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'BasketItem'.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'BasketItem'.
      #
      class BasketItem < ApiTools::Data::DocumentedKind

        define do
          integer :quantity, :required => true

          array :currency_amounts, :required => true do
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
