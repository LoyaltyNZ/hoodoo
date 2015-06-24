########################################################################
# File::    product.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Product'.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Product'.
      #
      class Product < Hoodoo::Presenters::Base

        schema do
          internationalised

          text :code
          text :name
          text :description

          # The legacy tags are left below to allow a seamless deploy since
          # many services are affected by the removal of tags. One they are all
          # deployed tags should be removed.
          tags :tags

        end

      end
    end
  end
end
