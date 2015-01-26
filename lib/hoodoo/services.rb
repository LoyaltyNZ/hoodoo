########################################################################
# File::    services.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include code useful to client service applications.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

# Dependencies

require 'hoodoo/logger'

# Services

require 'hoodoo/services/services/permissions'
require 'hoodoo/services/services/session'
require 'hoodoo/services/services/request'
require 'hoodoo/services/services/response'
require 'hoodoo/services/services/context'
require 'hoodoo/services/services/interface'
require 'hoodoo/services/services/implementation'
require 'hoodoo/services/services/application'
