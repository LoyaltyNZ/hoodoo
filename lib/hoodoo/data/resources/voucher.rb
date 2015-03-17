########################################################################
# File::    purchase.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Voucher'.
# ----------------------------------------------------------------------
#           11-Nov-2014 (JML): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'Voucher'.
      #
      class Voucher < Hoodoo::Presenters::Base

        # Defined values for the +state+ enumeration in the schema.
        #
        STATES = [ :earned, :burned ]

        # Defined values for the +reference_kind+ enumeration in the schema.
        #
        REFERENCE_KINDS = [ :Calculation ]

        schema do
          internationalised

          enum     :state,            :required => true, :from => STATES
          text     :token_identifier, :required => true
          text     :name,             :required => true
          text     :programme_code,   :required => true
          enum     :reference_kind,   :required => false,  :from     => REFERENCE_KINDS
          uuid     :reference_id,     :required => false
          integer  :time_to_live,     :required => false
          datetime :expires_after,    :required => false # note: this is a read only field
          hash     :burn_reason,      :required => false
        end

      end
    end
  end
end
