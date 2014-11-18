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
      class Calculator < ApiTools::Data::DocumentedPresenter

        schema do
          internationalised

          text   :name,                    :required => true
          text   :description,             :required => true
          enum   :type,                    :required => true,    :from => [ :earn_currency, :earn_vouchers ]
          type   :CalculatorConfiguration, :required => false
        end
      end
    end
  end
end
