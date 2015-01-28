########################################################################
# File::    constraints.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: DRY up length-related constraints by defining constant
#           values here.
# ----------------------------------------------------------------------
#           05-Nov-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Data
    module Types

      # Maximum permitted length of a Hoodoo::Data::Types::Currency +code+
      # field; constraint may apply in more than one type or resource.
      #
      CURRENCY_CODE_MAX_LENGTH      = 16

      # Maximum permitted length of a qualifier within a
      # Hoodoo::Data::Types::Currency +qualifiers+ array.
      #
      CURRENCY_QUALIFIER_MAX_LENGTH = 32

      # Maximum permitted length of a Hoodoo::Data::Types::Currency +symbol+
      # field; constraint may apply in more than one type or resource.
      #
      CURRENCY_SYMBOL_MAX_LENGTH    = 8

    end
  end
end
