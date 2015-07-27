########################################################################
# File::    financial_manipulation.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'FinancialManipulation'.
# ----------------------------------------------------------------------
#           09-Feb-2015 (DAM): Created.
#           22-Jul-2015 (JML): Added backdated_to.
########################################################################

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'FinancialManipulation'.
      #
      class FinancialManipulation < Hoodoo::Presenters::Base

        schema do
          internationalised

          text      :caller_reference, :required => true
          text      :description,      :required => false

          text      :token_identifier, :required => true
          datetime  :backdated_to,     :required => false
          object    :currency_amount,  :required => true do
            type    :CurrencyAmount
          end
        end

      end
    end
  end
end
