module ApiTools
  module Data

    # Documented Platform API Type 'BasketItem'.
    #
    class BasketItem < ApiTools::Data::DocumentedKind

      define do
        integer :quantity, :required => true

        array :currency_amounts, :required => true do
          type :CurrencyAmount
        end

        uuid :product_id, :resource => :Product
        text :product_code

        object :product_data do
          type :Product
        end

        enum :accrual, :from => [ :excluded ]
      end

    end
  end
end
