########################################################################
# File::    full_permissions.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define undocumented Platform API Type 'FullPermissions'.
#           This is currently for internal use but may be made available
#           to external callers in the future.
# ----------------------------------------------------------------------
#           2-Feb-2015 (RJS): Created.
########################################################################

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'FullPermissions'.
      #
      class FullPermissions < Hoodoo::Presenters::Base

        schema do

          type :ResourcePermissions
          type :DefaultPermissions

        end

      end
    end
  end
end
