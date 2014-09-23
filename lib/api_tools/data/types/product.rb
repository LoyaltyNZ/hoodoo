module ApiTools
  module Data

    # Documented Platform API Type 'Product'.
    #
    class Product < ApiTools::Data::DocumentedKind

      define do
        internationalised

        text :code
        text :name
        text :description

        tags :tags
      end

    end
  end
end
