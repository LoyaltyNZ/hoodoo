########################################################################
# File::    currency_amount.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'CurrencyAmount'.
# ----------------------------------------------------------------------
#           22-Sep-2014 (ADH): Created.
########################################################################

# Ruby namespace for the facilities provided by the ApiTools gem.
#
module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'CurrencyAmount'.
      #
      class CurrencyAmount < ApiTools::Data::DocumentedPresenter

        schema do
          string :currency_code, :required => true, :length => 16
          string :qualifier, :length => 32
          text :amount, :required => true
        end

      end
    end
  end
end
