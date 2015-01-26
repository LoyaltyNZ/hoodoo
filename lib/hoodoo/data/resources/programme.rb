########################################################################
# File::    product.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Programme'.
# ----------------------------------------------------------------------
#           23-Oct-2014 (JML): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Programme'.
      #
      class Programme < Hoodoo::Presenters::Base

        schema do
          internationalised

          text :code,          :required => :true
          text :name
          uuid :calculator_id, :resource => :Calculator
        end

      end
    end
  end
end
