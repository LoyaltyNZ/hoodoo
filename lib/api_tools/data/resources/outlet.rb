########################################################################
# File::    product.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Outlet'.
# ----------------------------------------------------------------------
#           29-Oct-2014 (JML): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Outlet'.
      #
      class Outlet < ApiTools::Data::DocumentedPresenter

        schema do
          internationalised

          text :name
          uuid :participant_id, :resource => :Participant, :required => true
          uuid :calculator_id,  :resource => :Calculator
        end

      end
    end
  end
end
