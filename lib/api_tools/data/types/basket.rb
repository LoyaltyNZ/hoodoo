########################################################################
# File::    basket.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'Basket'.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'Basket'.
      #
      class Basket < ApiTools::Presenters::Base

        schema do
          array :items do
            type :BasketItem
          end

          array :totals do
            type :CurrencyAmount
          end
        end

      end
    end
  end
end
