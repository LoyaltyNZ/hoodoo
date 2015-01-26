########################################################################
# File::    currency.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'Currency'.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
#           09-Oct-2014 (ADH): Updated for Preview Release 8.
########################################################################

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'Currency'.
      #
      class Currency < Hoodoo::Presenters::Base

        # Defined values for the +position+ enumeration in the schema.
        #
        POSITIONS = [ :prefix, :suffix ]

        # Defined values for the +rounding+ enumeration in the schema.
        #
        ROUNDINGS = [ :down, :up, :half_down, :half_up, :half_even ]

        # Defined values for the +external_currency_types+ enumeration in the schema.
        # see: https://github.com/LoyaltyNZ/awg/blob/master/prototype/platform_api.md#currency.type
        #
        EXTERNAL_TYPES = [ "nz.co.loyalty.txn.fbpts", "nz.co.loyalty.txn.apd" ]

        schema do
          string  :currency_code, :required => true, :length => Hoodoo::Data::Types::CURRENCY_CODE_MAX_LENGTH
          array   :qualifiers
          string  :symbol,                           :length => Hoodoo::Data::Types::CURRENCY_SYMBOL_MAX_LENGTH

          enum    :position, :from => POSITIONS
          enum    :rounding, :from => ROUNDINGS, :required => true

          integer :precision, :default => 2

        end

      end
    end
  end
end
