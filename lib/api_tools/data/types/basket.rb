module ApiTools
  module Data

    # Documented Platform API Type 'Basket'.
    #
    class Basket < ApiTools::Data::DocumentedKind

      define do
        array :items do
          type :BasketItem
        end

        array :totals do
          type :CurrencyAmount
        end
      end

    end
  end
end
