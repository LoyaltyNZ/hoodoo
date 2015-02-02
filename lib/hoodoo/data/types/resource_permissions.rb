########################################################################
# File::    resource_permissions.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Platform API Type 'ResourcePermissions'.
# ----------------------------------------------------------------------
#           30-Jan-2015 (RJS): Created.
########################################################################

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'ResourcePermissions'.
      #
      class ResourcePermissions < Hoodoo::Presenters::Base

        schema do

          hash :resources do
            keys do
              type :Permissions
            end
          end

        end

      end
    end
  end
end
