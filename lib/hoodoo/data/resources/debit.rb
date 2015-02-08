########################################################################
# File::    debit.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Debit'.
# ----------------------------------------------------------------------
#           09-Feb-2015 (DAM): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Debit'.
      #
      class Debit < Hoodoo::Presenters::Base

        schema do
          type   :FinancialManipulation
        end
      end
    end
  end
end
