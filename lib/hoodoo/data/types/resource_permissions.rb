########################################################################
# File::    resource_permissions.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Type 'ResourcePermissions'.
# ----------------------------------------------------------------------
#           30-Jan-2015 (RJS): Created.
########################################################################

require 'hoodoo/services/middleware/middleware'
require 'hoodoo/services/services/permissions'
module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'ResourcePermissions'.
      #
      class ResourcePermissions < Hoodoo::Presenters::Base

        schema do

          hash :resources do
            Hoodoo::Services::Middleware::ALLOWED_ACTIONS.each do |action|
              enum action,
                :from => Hoodoo::Services::Permissions::ALLOWED_POLICIES,
                :required => false
            end
          end

          enum :else, :from => Hoodoo::Services::Permissions::ALLOWED_POLICIES,
            :required => true
        end

      end
    end
  end
end
