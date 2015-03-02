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

# Middleware

require 'hoodoo/services/middleware/rack_monkey_patch'
require 'hoodoo/services/middleware/amqp_log_message'
require 'hoodoo/services/middleware/amqp_log_writer'
require 'hoodoo/services/middleware/interaction'
require 'hoodoo/services/middleware/endpoint/augmented_base'
require 'hoodoo/services/middleware/endpoint/augmented_hash'
require 'hoodoo/services/middleware/endpoint/augmented_array'
require 'hoodoo/services/middleware/endpoint/endpoint'
require 'hoodoo/services/middleware/middleware'

require 'hoodoo/services/middleware/exception_reporting/exception_reporting'
require 'hoodoo/services/middleware/exception_reporting/base_reporter'
require 'hoodoo/services/middleware/exception_reporting/reporters/airbrake_reporter'
require 'hoodoo/services/middleware/exception_reporting/reporters/raygun_reporter'
