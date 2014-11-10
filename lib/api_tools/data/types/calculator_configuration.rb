########################################################################
# File::    calculator_configuration.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type
#           'CalculatorConfiguration'.
# ----------------------------------------------------------------------
#           05-Nov-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'CalculatorConfiguration'.
      #
      class CalculatorConfiguration < ApiTools::Data::DocumentedPresenter

        schema do
          hash :calculator_data do
            key :earn_currency do
              type :CurrencyEarner
            end

            key :earn_vouchers do
              type :VoucherEarner
            end
          end
        end

      end
    end
  end
end
