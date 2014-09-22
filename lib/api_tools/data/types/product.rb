module ApiTools
  module Data

    # Documented Platform API Type 'Product'.
    #
    class Product < ApiTools::Data::DocumentedObject
      def initialize

        super

        internationalised

        text :code
        text :name
        text :description

        tags

      end
    end

  end
end
