module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'Currency'.
      #
      class Currency < ApiTools::Data::DocumentedKind

        define do
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
