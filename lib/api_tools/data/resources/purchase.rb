module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Purchase'.
      #
      class Purchase < ApiTools::Data::DocumentedKind

        define do
          text :token_identifier
          object :basket, :required => true do
            type :Basket
          end
          text :pos_reference
          uuid :estimation_id, :resource => :Estimation
          uuid :promotion_id, :resource => :Promotion, :required => true
        end

      end
    end
  end
end
