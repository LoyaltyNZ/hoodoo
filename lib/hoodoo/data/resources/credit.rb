########################################################################
# File::    credit.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Credit'.
# ----------------------------------------------------------------------
#           09-Feb-2015 (DAM): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Credit'.
      #
      class Credit < Hoodoo::Presenters::Base
        schema do
          type :FinancialManipulation
        end
      end
    end
  end
end
