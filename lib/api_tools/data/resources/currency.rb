########################################################################
# File::    currency.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Currency'.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Currency'.
      #
      class Currency < ApiTools::Presenters::Base

        schema do
          type :Currency
        end

      end
    end
  end
end
