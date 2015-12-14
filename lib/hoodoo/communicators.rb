########################################################################
# File::    communicators.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include the code providing a pool of fast or slow workers
#           that communicate with the outside world.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

module Hoodoo

  # The Communicators module is used as a namespace for
  # Hoodoo::Communicators::Pool and its related utility classes,
  # Hoodoo::Communicators::Fast and Hoodoo::Communicators::Fast.
  #
  module Communicators
  end
end

require 'hoodoo/communicators/pool'
require 'hoodoo/communicators/fast'
require 'hoodoo/communicators/slow'
