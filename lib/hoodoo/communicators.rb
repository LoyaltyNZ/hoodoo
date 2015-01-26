########################################################################
# File::    communicators.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include the code providing a pool of fast or slow workers
#           that communicate with the outside world.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

require 'communicators/pool'
require 'communicators/fast'
require 'communicators/slow'
