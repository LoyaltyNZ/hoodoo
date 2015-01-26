########################################################################
# File::    product.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'Product'.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'Product'.
      #
      class Product < Hoodoo::Presenters::Base

        schema do
          internationalised

          text :code
          text :name
          text :description

          tags :tags
        end

      end
    end
  end
end
