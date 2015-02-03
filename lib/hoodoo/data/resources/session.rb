########################################################################
# File::    session.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Platform API Resource 'Session'.
# ----------------------------------------------------------------------
#           30-Jan-2015 (RJS): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Session'.
      #
      class Session < Hoodoo::Presenters::Base

        schema do
          uuid     :caller_id,  :required => true, :resource => :Caller
          datetime :expires_at, :required => true
          text     :identifier, :required => true
        end

      end
    end
  end
end
