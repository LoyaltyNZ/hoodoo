########################################################################
# File::    permissions_full.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define utility Type 'PermissionsFull'.
# ----------------------------------------------------------------------
#           02-Feb-2015 (RJS): Created.
########################################################################

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'PermissionsFull'.
      #
      class PermissionsFull < Hoodoo::Presenters::Base

        schema do

          type :PermissionsResources
          type :PermissionsDefaults

        end

      end
    end
  end
end
