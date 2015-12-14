########################################################################
# File::    middleware.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include code implementing the Rack service middleware.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

# Dependencies

require 'hoodoo/utilities'
require 'hoodoo/errors'
require 'hoodoo/communicators'
require 'hoodoo/logger'
require 'hoodoo/discovery'
require 'hoodoo/client'
require 'hoodoo/presenters'

# Middleware

require 'hoodoo/services/middleware/rack_monkey_patch'
require 'hoodoo/services/middleware/amqp_log_message'
require 'hoodoo/services/middleware/amqp_log_writer'
require 'hoodoo/services/middleware/interaction'
require 'hoodoo/services/middleware/endpoints/inter_resource_remote'
require 'hoodoo/services/middleware/endpoints/inter_resource_local'
require 'hoodoo/services/middleware/middleware'

require 'hoodoo/services/middleware/exception_reporting/exception_reporting'
require 'hoodoo/services/middleware/exception_reporting/base_reporter'
require 'hoodoo/services/middleware/exception_reporting/reporters/airbrake_reporter'
require 'hoodoo/services/middleware/exception_reporting/reporters/raygun_reporter'
