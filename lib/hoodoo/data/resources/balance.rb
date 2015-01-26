########################################################################
# File::    balance.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Balance'.
# ----------------------------------------------------------------------
#           07-Nov-2014 (DAM): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Balance'.
      #
      class Balance < Hoodoo::Presenters::Base

        schema do
          text :token_identifier,  :required => true

          object :currency_amount, :required => true do
            type :CurrencyAmount
          end
        end

      end
    end
  end
end
