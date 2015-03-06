########################################################################
# File::    augmented_array.rb.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A subclass of Ruby standard library Array used by the
#           Hoodoo::Client::Endpoint family.
# ----------------------------------------------------------------------
#           11-Dec-2014 (ADH): Created.
#           05-Mar-2015 (ADH): Moved to Hoodoo::Client.
########################################################################

module Hoodoo
  module Client

    # Ruby standard library Hash subclass which mixes in
    # Hoodoo::Client::AugmentedBase. See that for details.
    #
    class AugmentedHash < ::Hash
      include Hoodoo::Client::AugmentedBase
    end

  end
end
