########################################################################
# File::    discovery.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include code that helps with finding resource endpoints.
# ----------------------------------------------------------------------
#           02-Mar-2015 (ADH): Created
########################################################################

require 'hoodoo/services/discovery/discovery'

require 'hoodoo/services/discovery/results/for_http'
require 'hoodoo/services/discovery/results/for_amqp'
require 'hoodoo/services/discovery/results/for_local'
require 'hoodoo/services/discovery/results/for_remote'

require 'hoodoo/services/discovery/discoverers/by_convention'
require 'hoodoo/services/discovery/discoverers/by_flux'
require 'hoodoo/services/discovery/discoverers/by_drb/drb_server'
require 'hoodoo/services/discovery/discoverers/by_drb/by_drb'
