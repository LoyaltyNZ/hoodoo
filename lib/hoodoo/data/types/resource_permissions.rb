########################################################################
# File::    resource_permissions.rb
# (C)::     Loyalty New Zealand 2014
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

        # Defined values for the +actions+ keys in the schema. These are
        # to actions which can be performed on resources.
        #
        ACTIONS = [ :show, :list, :create, :update, :delete ]

        # Defined policies which are applied to actions in the schema.
        #
        POLICIES = [ :allow, :deny, :ask ]

        schema do

          hash :resources do
            ACTIONS.each do |action|
              enum action, :from => POLICIES, :required => false
            end
          end

          enum :else, :from => POLICIES, :required => true
        end

      end
    end
  end
end
