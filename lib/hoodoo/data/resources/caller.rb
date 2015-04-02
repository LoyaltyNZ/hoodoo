########################################################################
# File::    caller.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Platform API Resource 'Caller'.
# ----------------------------------------------------------------------
#           30-Jan-2015 (RJS): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Caller'.
      #
      class Caller < Hoodoo::Presenters::Base

        schema do
          internationalised

          text :authentication_secret
          text :name

          hash :identity do
          end

          type :PermissionsResources, :required => true

          hash :scoping do
          end

        end

      end
    end
  end
end
