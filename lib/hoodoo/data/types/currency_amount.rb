########################################################################
# File::    currency_amount.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'CurrencyAmount'.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'CurrencyAmount'.
      #
      class CurrencyAmount < Hoodoo::Presenters::Base

        schema do
          string :currency_code, :required => true, :length => Hoodoo::Data::Types::CURRENCY_CODE_MAX_LENGTH
          string :qualifier, :length => Hoodoo::Data::Types::CURRENCY_QUALIFIER_MAX_LENGTH
          text :amount, :required => true
        end

      end
    end
  end
end
