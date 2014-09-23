module ApiTools
  module Data
    module Types

      # Documented Platform API Type 'ErrorPrimitive'.
      #
      class ErrorPrimitive < ApiTools::Data::DocumentedKind

        define do
          text :code, :required => true
          text :message, :required => true
          text :reference
        end

      end
    end
  end
end
