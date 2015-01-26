########################################################################
# File::    voucher_earner.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'VoucherEarner'.
# ----------------------------------------------------------------------
#           05-Nov-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'VoucherEarner'.
      #
      class VoucherEarner < Hoodoo::Presenters::Base

        # Defined values for the +accumulation+ enumeration in the schema.
        #
        ACCUMULATIONS = [ :discrete, :cumulative ]

        # Since this can be used in many contexts, including partial
        # fragments in e.g. Involvements or Memberships, none of the
        # required fields can get labelled as such. Requirements refer
        # to *overall* required data when everything is merged.

        schema do
          internationalised

          type :CalculatorCommon

          array :voucher_earners do
            object :earned_via do
              enum :accumulation, :from => ACCUMULATIONS
              hash :source_exchange_rates do
                keys :length => Hoodoo::Data::Types::CURRENCY_CODE_MAX_LENGTH
              end
            end

            object :build_with do
              text :name
            end
          end
        end

      end
    end
  end
end
