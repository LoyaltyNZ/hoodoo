########################################################################
# File::    calculator_common.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type
#           'CalculatorCommon'.
# ----------------------------------------------------------------------
#           05-Nov-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'CalculatorCommon'.
      #
      class CalculatorCommon < Hoodoo::Presenters::Base

        schema do
          array :product_tag_ids_included
          array :product_tag_ids_excluded

          # The legacy tags are left below to allow a seamless deploy since
          # many services are affected by the removal of tags. Once they are all
          # deployed tags should be removed.
          array :product_tag_ids_included
          array :product_tag_ids_excluded
        end

      end
    end
  end
end
