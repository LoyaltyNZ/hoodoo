########################################################################
# File::    transaction.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Define documented Platform API Resource 'Transaction'.
#            Please note that the name 'Transaction' is kind of a place
#            holder until (if ever) we decide on something better
# ----------------------------------------------------------------------
#           13-Nov-2014 (DAM): Created.
########################################################################

module ApiTools
  module Data
    module Resources

      # Documented Platform API Resource 'Transaction'.
      #
      class Transaction < ApiTools::Presenters::Base

        # Defined values for the +business_operation+ enumeration in the
        # schema.
        #
        BUSINESS_OPERATIONS = [ :transfer, :earn, :reverse ]

        schema do
          internationalised

          uuid     :client_id,                    :required => true
          enum     :business_operation,           :required => true, :from => BUSINESS_OPERATIONS
          text     :description,                  :required => true

          datetime :transaction_time,             :required => true
          datetime :client_processed_time,        :required => true
          datetime :platform_processed_time,      :required => true

          text     :destination_token_identifier, :required => true

          text     :source_token_identifier,      :required => false
          array    :currency_amounts,             :required => false do
            type   :CurrencyAmount
          end

        end
      end
    end
  end
end
