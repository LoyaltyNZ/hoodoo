########################################################################
# File::    augmented_array.rb.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A subclass of Ruby standard library Array used by the
#           Hoodoo::Services::Middleware::Endpoint family of
#           inter-resource calls.
# ----------------------------------------------------------------------
#           11-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo; module Services
  class Middleware

    class Endpoint < Hoodoo::Services::Middleware

      # Ruby standard library Array subclass which mixes in
      # Hoodoo::Services::Middleware::Endpoint::AugmentedBase.
      # See that for details.
      #
      class AugmentedArray < ::Array
        include Hoodoo::Services::Middleware::Endpoint::AugmentedBase
      end

    end

  end
end; end
