########################################################################
# File::    membership.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Token'.
# ----------------------------------------------------------------------
#           03-Dec-2014 (RJS): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Membership'.
      #
      class Membership < ApiTools::Presenters::Base

        schema do
          text :token_identifier, required: true
          uuid :programme_id,     required: true, resource: :Programme
          type :CalculatorConfiguration
        end

      end
    end
  end
end
