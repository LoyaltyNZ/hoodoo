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
          uuid :participant_id,              :required => true, :resource => :Participant
          uuid :outlet_id,                   :required => true, :resource => :Outlet
          text :authentication_secret

          type :PermissionsResources,        :required => true

          array :authorised_participant_ids, :required => true

          array :authorised_programme_codes, :required => true
        end

      end
    end
  end
end
