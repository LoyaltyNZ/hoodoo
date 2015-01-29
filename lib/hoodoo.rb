########################################################################
# File::    hoodoo.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include all parts of Hoodoo.
# ----------------------------------------------------------------------
#           29-Jan-2015 (ADH): Added file documentation.
########################################################################

# Module used as a namespace for all of Hoodoo's facilities.
#
module Hoodoo
end

require 'hoodoo/utilities'
require 'hoodoo/communicators'
require 'hoodoo/logger'
require 'hoodoo/presenters'
require 'hoodoo/data'
require 'hoodoo/errors'
require 'hoodoo/services'
require 'hoodoo/middleware'
require 'hoodoo/active'

require 'hoodoo/version'
