########################################################################
# File::    product.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Participant'.
# ----------------------------------------------------------------------
#           23-Oct-2014 (JML): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Participant'.
      #
      class Participant < Hoodoo::Presenters::Base

        schema do
          internationalised

          text :name
        end

      end
    end
  end
end
