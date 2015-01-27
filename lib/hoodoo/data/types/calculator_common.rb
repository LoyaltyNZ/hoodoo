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
          tags :product_tags_included
          tags :product_tags_excluded
        end

      end
    end
  end
end
