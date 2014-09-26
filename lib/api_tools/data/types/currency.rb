########################################################################
# File::    currency.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'Currency'.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'Currency'.
      #
      class Currency < ApiTools::Data::DocumentedPresenter

        schema do
          string :currency_code, :required => true, :length => 8
          string :symbol, :length => 16
          integer :multiplier, :default => 100
          array :qualifiers do
            string :qualifier, :length => 32
          end
        end

      end
    end
  end
end
