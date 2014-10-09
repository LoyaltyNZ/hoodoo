########################################################################
# File::    currency.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'Currency'.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
#           09-Oct-2014 (ADH): Updated for Preview Release 8.
########################################################################

module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'Currency'.
      #
      class Currency < ApiTools::Data::DocumentedPresenter

        schema do
          string :currency_code, :required => true, :length => 16
          array :qualifiers
          string :symbol, :length => 8
          enum :position, :from => [ :prefix, :suffix ]

          integer :precision, :default => 2
          enum :rounding, :from => [ :down, :up, :half_down, :half_up, :half_even ], :required => true
        end

      end
    end
  end
end
