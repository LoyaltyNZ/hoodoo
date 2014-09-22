module ApiTools
  module Data

    # Documented Platform API Type 'ErrorPrimitive'.
    #
    class ErrorPrimitive < ApiTools::Data::DocumentedObject
      def initialize

        super

        text :code, :required => true
        text :message, :required => true
        text :reference

      end
    end

  end
end
