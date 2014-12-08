########################################################################
# File::    purchase.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Voucher'.
# ----------------------------------------------------------------------
#           11-Nov-2014 (JML): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Voucher'.
      #
      class Voucher < ApiTools::Presenters::Base

        # Defined values for the +state+ enumeration in the schema.
        #
        STATES = [ :earned, :burned ]

        schema do
          internationalised

          enum  :state, :from => STATES
          text  :token_identifier
          text  :name
          hash  :burn_reason
        end

      end
    end
  end
end
