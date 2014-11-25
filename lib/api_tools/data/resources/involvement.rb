########################################################################
# File::    product.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Involvement'.
# ----------------------------------------------------------------------
#           29-Oct-2014 (JML): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Involvement'.
      #
      class Involvement < ApiTools::Data::DocumentedPresenter

        schema do
          uuid   :outlet_id,      :resource => :Outlet,     :required => true
          uuid   :programme_id,   :resource => :Programme,  :required => true
          type   :CalculatorConfiguration
        end

      end
    end
  end
end
