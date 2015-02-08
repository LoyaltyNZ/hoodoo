########################################################################
# File::    credit.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Credit'.
# ----------------------------------------------------------------------
#           09-Feb-2015 (DAM): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Credit'.
      #
      class Credit < Hoodoo::Presenters::Base

        schema do
          internationalised

          uuid     :client_id,                    :required => true
          text     :description,                  :required => false

          text     :token_identifier,             :required => true
          object   :currency_amount,             :required => true do
            type   :CurrencyAmount
          end

        end
      end
    end
  end
end
