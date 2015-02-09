########################################################################
# File::    permissions.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Platform API Type 'Permissions'.
# ----------------------------------------------------------------------
#           02-Feb-2015 (RJS): Created.
########################################################################

require 'hoodoo/services/middleware/middleware'
require 'hoodoo/services/services/permissions'

module Hoodoo
  module Data
    module Types

      # Documented Platform API Type 'Permissions'.
      #
      class Permissions < Hoodoo::Presenters::Base

        schema do

          object :actions do
            Hoodoo::Services::Middleware::ALLOWED_ACTIONS.each do | action |
              enum action,
                   :from     => Hoodoo::Services::Permissions::ALLOWED_POLICIES,
                   :required => false
            end
          end

          enum :else,
               :from     => Hoodoo::Services::Permissions::ALLOWED_POLICIES,
               :required => false

        end

      end
    end
  end
end
