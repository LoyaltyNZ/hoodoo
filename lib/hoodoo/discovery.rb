########################################################################
# File::    discovery.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include code that helps with finding resource endpoints.
# ----------------------------------------------------------------------
#           02-Mar-2015 (ADH): Created
########################################################################

module Hoodoo
  module Services

    # Module providing a namespace for code useful to client service
    # discovery - the location of actual resource endpoints over things
    # like an HTTP or AMQP based architecture.
    #
    module Discovery
    end
  end
end

# Services

require 'hoodoo/services/discovery/results/for_http'
require 'hoodoo/services/discovery/results/for_amqp'

require 'hoodoo/services/discovery/base'

require 'hoodoo/services/discovery/discoverers/by_convention'
require 'hoodoo/services/discovery/discoverers/by_consul'
require 'hoodoo/services/discovery/discoverers/by_drb/drb_server'
require 'hoodoo/services/discovery/discoverers/by_drb/by_drb'
