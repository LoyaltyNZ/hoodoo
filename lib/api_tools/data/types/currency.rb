########################################################################
# File::    currency.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'Currency'.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
#           09-Oct-2014 (ADH): Updated for Preview Release 8.
########################################################################

module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'Currency'.
      #
      class Currency < ApiTools::Presenters::Base

        # Defined values for the +position+ enumeration in the schema.
        #
        POSITIONS = [ :prefix, :suffix ]

        # Defined values for the +rounding+ enumeration in the schema.
        #
        ROUNDINGS = [ :down, :up, :half_down, :half_up, :half_even ]

        schema do
          string  :currency_code, :required => true, :length => ApiTools::Data::Types::CURRENCY_CODE_MAX_LENGTH
          array   :qualifiers
          string  :symbol,                           :length => ApiTools::Data::Types::CURRENCY_SYMBOL_MAX_LENGTH
          enum    :position, :from => POSITIONS

          integer :precision, :default => 2
          enum    :rounding,  :from    => ROUNDINGS, :required => true
        end

      end
    end
  end
end
