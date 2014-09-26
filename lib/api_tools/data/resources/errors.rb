########################################################################
# File::    errors.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Errors'.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

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
