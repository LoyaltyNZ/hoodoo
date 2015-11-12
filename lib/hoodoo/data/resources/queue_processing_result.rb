########################################################################
# File::    queue_processing_result.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Define documented Internal Platform API Resource
#           'QueueProcessingResult'.
# ----------------------------------------------------------------------
#           22-Sep-2015 (RJS): Created.
########################################################################

module Hoodoo
  module Data
    module Resources

      # Documented Platform API Resource 'QueueProcessingResult'.
      #
      class QueueProcessingResult < Hoodoo::Presenters::Base

        # Defined values for the +status+ enumeration in the schema.
        #
        STATUSES = [ :processed, :deferred ]

        schema do
          enum :status, :from => STATUSES
          uuid :queue_processing_request_id, :resource => :QueueProcessingRequest
          array :platform_results
        end
      end
    end
  end
end
