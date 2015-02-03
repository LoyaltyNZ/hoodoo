########################################################################
# File::    permissions_defaults.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define undocumented Platform API Type 'PermissionsDefaults'.
#           This type is currently for internal use but may be exposed
#           to external callers in the future.
# ----------------------------------------------------------------------
#           02-Feb-2015 (RJS): Created.
########################################################################

require 'hoodoo/services/services/permissions'

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'PermissionsDefaults'.
      #
      class PermissionsDefaults < Hoodoo::Presenters::Base

        schema do

          object :default,
                 :default => { 'else' => Hoodoo::Services::Permissions::DENY } do
            type :Permissions
          end

        end

      end
    end
  end
end
