########################################################################
# File::    queue_processing_request.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Internal Platform API Resource
#           'QueueProcessingRequest'.
# ----------------------------------------------------------------------
#           22-Seo-2015 (RJS): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'QueueProcessingRequest'.
      #
      class QueueProcessingRequest < Hoodoo::Presenters::Base

        # Defined values for the +state+ enumeration in the schema.
        #
        STATES = [ :processed, :deferred ]

        schema do
          text :message_reference
          enum :state, :from => STATES
          datetime  :queued_at
          uuid :caller_outlet_id, :resource => :Outlet
          hash :caller_identity do; end
          hash :info do; end

          array :platform_requests
          array :payload_errors
        end
      end
    end
  end
end
