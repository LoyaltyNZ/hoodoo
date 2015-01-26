########################################################################
# File::    services.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include code useful to client service applications.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

# Dependencies

require 'logger'

# Services

require 'services/services/permissions'
require 'services/services/session'
require 'services/services/request'
require 'services/services/response'
require 'services/services/context'
require 'services/services/interface'
require 'services/services/implementation'
require 'services/services/application'
