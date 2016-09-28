########################################################################
# File::    client.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Include code that makes it easy to call resource endpoints.
# ----------------------------------------------------------------------
#           10-Mar-2015 (ADH): Created
########################################################################

require 'hoodoo/client/headers'

require 'hoodoo/client/augmented_base'
require 'hoodoo/client/enumeration_state'
require 'hoodoo/client/augmented_hash'
require 'hoodoo/client/augmented_array'

require 'hoodoo/client/endpoint/endpoint'
require 'hoodoo/client/endpoint/endpoints/http_based'
require 'hoodoo/client/endpoint/endpoints/http'
require 'hoodoo/client/endpoint/endpoints/amqp'
require 'hoodoo/client/endpoint/endpoints/not_found'
require 'hoodoo/client/endpoint/endpoints/auto_session'

require 'hoodoo/client/client'
