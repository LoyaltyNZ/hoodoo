########################################################################
# File::    ledger.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Ledger'.
# ----------------------------------------------------------------------
#           08-Jan-2015 (DAM): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Ledger'.
      #
      class Ledger < ApiTools::Presenters::Base

        # Defined values for the +reason+ enumeration in the schema.
        #
        REASONS = [ :calculation, :manipulation ]

        schema do
          text   :token_identifier, :required => true
          uuid   :participant_id,   :required => true, :resource => :Participant
          uuid   :outlet_id,        :required => true, :resource => :Outlet
          enum   :reason,           :required => true, :from     => REASONS

          object :debit,            :required => false do
            type :CurrencyAmount
          end
          object :credit,           :required => false do
            type :CurrencyAmount
          end
        end
      end
    end
  end
end
