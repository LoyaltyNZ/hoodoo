########################################################################
# File::    basket_product.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'BasketProduct'.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
#           17-Jun-2015 (DJS): Changed from Product to BasketProduct
########################################################################

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'BasketProduct'.
      #
      class BasketProduct < Hoodoo::Presenters::Base

        schema do
          internationalised

          text  :code
          text  :name
          text  :description

          array :tag_ids
        end

      end
    end
  end
end
