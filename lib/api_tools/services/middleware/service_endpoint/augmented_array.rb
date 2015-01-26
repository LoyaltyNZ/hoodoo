########################################################################
# File::    augmented_array.rb.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A subclass of Ruby standard library Array used by the
#           Hoodoo::ServiceMiddleware::ServiceEndpoint family of
#           inter-resource calls.
# ----------------------------------------------------------------------
#           11-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo
  class ServiceMiddleware
    class ServiceEndpoint < Hoodoo::ServiceMiddleware

      # Ruby standard library Array subclass which mixes in
      # Hoodoo::ServiceMiddleware::ServiceEndpoint::AugmentedBase.
      # See that for details.
      #
      class AugmentedArray < ::Array
        include Hoodoo::ServiceMiddleware::ServiceEndpoint::AugmentedBase
      end

    end
  end
end
