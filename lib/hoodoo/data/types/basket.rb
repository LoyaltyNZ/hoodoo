########################################################################
# File::    basket.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'Basket'.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'Basket'.
      #
      class Basket < Hoodoo::Presenters::Base

        schema do
          array :items, :required => false do
            type :BasketItem
          end

          array :totals, :required => true do
            type :CurrencyAmount
          end
        end

      end
    end
  end
end
