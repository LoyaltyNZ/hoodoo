########################################################################
# File::    middleware.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include code implementing the Rack service middleware.
# ----------------------------------------------------------------------
#           26-Jan-2015 (ADH): Split from top-level inclusion file.
########################################################################

# Dependencies

require 'errors'
require 'communicators'
require 'logger'

# Middleware

require 'services/middleware/rack_monkey_patch'
require 'services/middleware/string_inquirer'
require 'services/middleware/amqp_log_message'
require 'services/middleware/amqp_log_writer'
require 'services/middleware/endpoint/augmented_base'
require 'services/middleware/endpoint/augmented_hash'
require 'services/middleware/endpoint/augmented_array'
require 'services/middleware/endpoint/endpoint'
require 'services/middleware/service_registry_drb_server'
require 'services/middleware/middleware'

require 'services/middleware/exception_reporting/exception_reporting'
require 'services/middleware/exception_reporting/base_reporter'
require 'services/middleware/exception_reporting/reporters/airbrake_reporter'
require 'services/middleware/exception_reporting/reporters/raygun_reporter'
