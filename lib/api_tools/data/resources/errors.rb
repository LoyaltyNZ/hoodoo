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
    module Resources

      # Documented Platform API Resource 'Errors'.
      #
      class Errors < ApiTools::Data::DocumentedPresenter

        schema do
          array :errors do
            type :ErrorPrimitive
          end
        end

      end
    end
  end
end