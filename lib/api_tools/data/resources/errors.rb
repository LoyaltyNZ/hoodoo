module ApiTools
  module Data

    # Module used as a namespace to collect classes that represent Resources
    # documented by the Loyalty Platform API. Each can be instantiated and
    # used for JSON validation purposes - see
    # ApiTools::Data::DocumentedKind#initialize for details.
    #
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
