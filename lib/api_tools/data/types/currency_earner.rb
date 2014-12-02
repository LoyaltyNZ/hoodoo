########################################################################
# File::    currency_earner.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'CurrencyEarner'.
# ----------------------------------------------------------------------
#           05-Nov-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'CurrencyEarner'.
      #
      class CurrencyEarner < ApiTools::Presenters::Base

        # Since this can be used in many contexts, including partial
        # fragments in e.g. Involvements or Memberships, none of the
        # required fields can get labelled as such. Requirements refer
        # to *overall* required data when everything is merged.

        schema do
          type :CalculatorCommon

          object :currency_earner do
            hash :earned_via do
              keys :length => ApiTools::Data::Types::CURRENCY_CODE_MAX_LENGTH do
                integer :amount
                string :qualifier, :length => ApiTools::Data::Types::CURRENCY_QUALIFIER_MAX_LENGTH
                enum :accumulation, :from => [ :discrete, :cumulative ]
                hash :source_exchange_rates do
                  keys :length => ApiTools::Data::Types::CURRENCY_CODE_MAX_LENGTH
                end
              end
            end

            array :default_currency_code
          end
        end

      end
    end
  end
end
