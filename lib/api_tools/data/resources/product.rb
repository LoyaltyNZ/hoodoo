########################################################################
# File::    product.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Product'.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Product'.
      #
      class Product < ApiTools::Presenters::Base

        schema do
          type :Product
        end

      end
    end
  end
end
