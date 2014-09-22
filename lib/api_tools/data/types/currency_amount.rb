module ApiTools
  module Data

    # Documented Platform API Type 'CurrencyAmount'.
    #
    class CurrencyAmount < ApiTools::Data::DocumentedObject
      def initialize

        super

        string :curency_code, :required => true, :length => 8
        string :qualifier, :length => 32
        text :amount, :required => true

      end
    end

  end
end
