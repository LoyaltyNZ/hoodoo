module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'CurrencyAmount'.
      #
      class CurrencyAmount < ApiTools::Data::DocumentedKind

        define do
          string :curency_code, :required => true, :length => 8
          string :qualifier, :length => 32
          text :amount, :required => true
        end

      end
    end
  end
end
