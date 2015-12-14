########################################################################
# File::    errors.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Errors'.
# ----------------------------------------------------------------------
#           23-Sep-2014 (ADH): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Errors'.
      #
      class Errors < Hoodoo::Presenters::Base

        schema do
          uuid :interaction_id
          array :errors, :required => true do
            type :ErrorPrimitive
          end
        end

      end
    end
  end
end
