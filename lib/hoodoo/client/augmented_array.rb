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
  class Client # Just used as a namespace here

    # Ruby standard library Array subclass which mixes in
    # Hoodoo::Client::AugmentedBase. See that for details.
    #
    class AugmentedArray < ::Array
      include Hoodoo::Client::AugmentedBase
      include Hoodoo::Client::EnumerationState

      # For lists, the (optional) total size of the data set, of which
      # the contents of this Array will often only represent a single
      # page. If unknown, the value is +nil+, but as an alternative, an
      # estimated size may be available in #estimated_dataset_size.
      #
      attr_accessor :dataset_size

      # For lists, the (optional) estimated size of the data set, of
      # which the contents of this Array will often only represent a
      # single page. If unknown, the value is +nil+. The accuracy of
      # the estimation is unknown.
      #
      attr_accessor :estimated_dataset_size

    end

  end
end
