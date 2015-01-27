########################################################################
# File::    token.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Token'.
# ----------------------------------------------------------------------
#           07-Nov-2014 (DAM): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Token'.
      #
      class Token < Hoodoo::Presenters::Base

        # Defined values for the +state+ enumeration in the schema.
        #
        STATES = [ :waiting, :active, :closed ]

        schema do
          enum :state,      :from     => STATES
          text :identifier, :required => true
          uuid :member_id,  :required => true, :resource => :Member
        end

      end
    end
  end
end
