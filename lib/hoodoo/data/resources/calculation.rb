########################################################################
# File::    calculation.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Calculation'.
# ----------------------------------------------------------------------
#           17-Nov-2014 (DAM): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Calculation'.
      #
      class Calculation < Hoodoo::Presenters::Base

      # Defined values for the +reference_name+ enumeration in the schema.
      #
      REFERENCE_NAMES = [ :Calculation, :Credit, :Debit ]

        schema do
          uuid  :calculator_id,           :required => true,   :resource => :Calculator
          text  :token_identifier,        :required => true
          text  :programme_code,          :required => true
          text  :reference_name,          :required => false,  :from     => REFERENCE_NAMES
          uuid  :reference_id,            :required => false
          type  :CalculatorConfiguration, :required => false
          array :currency_amounts,        :required => true do
            type :CurrencyAmount
          end
        end
      end
    end
  end
end
