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
          text :authentication_secret_parameter_store_path, :required => false
          text :name
          uuid :fingerprint, :required => false

          hash :identity, :required => true do
          end

          object :permissions, :required => true do
            type :PermissionsResources, :required => true
          end

          hash :scoping, :required => true do
          end

        end

      end
    end
  end
end
