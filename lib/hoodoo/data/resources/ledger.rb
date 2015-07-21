########################################################################
# File::    ledger.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Ledger'.
# ----------------------------------------------------------------------
#           08-Jan-2015 (DAM): Created.
#           22-Jul-2015 (JML): Added backdated_to.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Ledger'.
      #
      class Ledger < Hoodoo::Presenters::Base

        # Defined values for the +reason+ enumeration in the schema.
        #
        REASONS = [ :calculation, :manipulation ]

        # Defined values for the +reference_kind+ enumeration in the schema.
        #
        REFERENCE_KINDS = [ :Calculation, :Credit, :Debit ]

        schema do
          text     :token_identifier, :required => true
          datetime :backdated_to,     :required => true
          uuid     :participant_id,   :required => true,  :resource => :Participant
          uuid     :outlet_id,        :required => true,  :resource => :Outlet
          enum     :reason,           :required => true,  :from     => REASONS

          enum     :reference_kind,   :required => false, :from     => REFERENCE_KINDS
          uuid     :reference_id,     :required => false

          object   :debit,            :required => false do
            type :CurrencyAmount
          end
          object   :credit,           :required => false do
            type :CurrencyAmount
          end
        end
      end
    end
  end
end
