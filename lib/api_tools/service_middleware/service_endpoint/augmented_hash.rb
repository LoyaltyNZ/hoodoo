########################################################################
# File::    augmented_array.rb.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A subclass of Ruby standard library Array used by the
#           ApiTools::ServiceMiddleware::ServiceEndpoint family of
#           inter-resource calls.
# ----------------------------------------------------------------------
#           11-Dec-2014 (ADH): Created.
########################################################################

module ApiTools
  class ServiceMiddleware
    class ServiceEndpoint < ApiTools::ServiceMiddleware

      # Ruby standard library Hash subclass which mixes in
      # ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedBase.
      # See that for details.
      #
      class AugmentedHash < ::Hash
        include ApiTools::ServiceMiddleware::ServiceEndpoint::AugmentedBase
      end

    end
  end
end
