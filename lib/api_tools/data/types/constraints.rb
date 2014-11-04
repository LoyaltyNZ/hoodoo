########################################################################
# File::    constraints.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: DRY up length-related constraints by defining constant
#           values here.
# ----------------------------------------------------------------------
#           05-Nov-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data
    module Types

      CURRENCY_CODE_MAX_LENGTH      = 16
      CURRENCY_QUALIFIER_MAX_LENGTH = 32
      CURRENCY_SYMBOL_MAX_LENGTH    = 8

    end
  end
end
