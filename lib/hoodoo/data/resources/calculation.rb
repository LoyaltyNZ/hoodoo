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

      # Defined values for the +reference_kind+ enumeration in the schema.
      #
      REFERENCE_KINDS = [ :Purchase ]

        schema do
          text  :token_identifier,        :required => true
          text  :programme_code,          :required => true
          enum  :reference_kind,          :required => false,  :from     => REFERENCE_KINDS
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
