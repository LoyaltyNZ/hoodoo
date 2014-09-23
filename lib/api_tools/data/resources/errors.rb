module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Errors'.
      #
      class Errors < ApiTools::Data::DocumentedKind

        define do
          array :errors do
            type :ErrorPrimitive
          end
        end

      end
    end
  end
end
