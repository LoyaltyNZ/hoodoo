########################################################################
# File::    product.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Programme'.
# ----------------------------------------------------------------------
#           23-Oct-2014 (JML): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Programme'.
      #
      class Programme < ApiTools::Data::DocumentedPresenter

        schema do
          internationalised

          text :code
          text :name
        end

      end
    end
  end
end
