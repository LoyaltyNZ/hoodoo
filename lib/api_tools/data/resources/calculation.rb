########################################################################
# File::    balance.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Calculation'.
# ----------------------------------------------------------------------
#           17-Nov-2014 (DAM): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Calculation'.
      #
      class Calculation < ApiTools::Data::DocumentedPresenter

        schema do
          uuid :calculator_id,     :required => true,   :resource => :Calculator
          object :configuration,   :required => true do
            type :CalculatorConfiguration
          end
          array :currency_amounts, :required => true do
            type :CurrencyAmount
          end
        end
      end
    end
  end
end
