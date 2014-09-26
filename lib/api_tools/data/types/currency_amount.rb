########################################################################
# File::    currency_amount.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'CurrencyAmount'.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'CurrencyAmount'.
      #
      class CurrencyAmount < ApiTools::Data::DocumentedPresenter

        schema do
          string :curency_code, :required => true, :length => 8
          string :qualifier, :length => 32
          text :amount, :required => true
        end

      end
    end
  end
end
