########################################################################
# File::    product.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Programme'.
# ----------------------------------------------------------------------
#           23-Oct-2014 (JML): Created.
#           01-Apr-2015 (JML): Added CalculatorConfiguration.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Programme'.
      #
      class Programme < Hoodoo::Presenters::Base

        schema do
          internationalised

          text  :code,                    :required => :true
          text  :name
          uuid  :calculator_id,           :resource => :Calculator
          type  :CalculatorConfiguration, :required => false
        end

      end
    end
  end
end
