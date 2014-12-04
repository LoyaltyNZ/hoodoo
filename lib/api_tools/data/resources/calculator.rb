########################################################################
# File::    calculator.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Calculator'.
# ----------------------------------------------------------------------
#           17-Nov-2014 (DAM): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Calculator'.
      #
      class Calculator < ApiTools::Presenters::Base

        # Defined values for the +calculator_type+ enumeration in the schema.
        #
        CALCULATOR_TYPES = [ :earn_currency, :earn_vouchers ]

        schema do
          internationalised

          text   :name,                    :required => true
          text   :description,             :required => true
          enum   :calculator_type,         :required => true, :from => CALCULATOR_TYPES
          type   :CalculatorConfiguration, :required => false
        end
      end
    end
  end
end
