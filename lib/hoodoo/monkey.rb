########################################################################
# File::    monkey.rb
# (C)::     Loyalty New Zealand 2016
#
# Purpose:: Require the Hoodoo monkey patching engine and any built-in
#           patches, which will enable themselves (or not) according to
#           their individual RDoc-documented descriptions.
# ----------------------------------------------------------------------
#           12-Apr-2016 (ADH): Created.
########################################################################

require 'hoodoo/monkey/monkey'

require 'hoodoo/monkey/patch/active_record_dated_finder_additions'
require 'hoodoo/monkey/patch/active_record_manually_dated_finder_additions'
require 'hoodoo/monkey/patch/datadog_traced_amqp'
require 'hoodoo/monkey/patch/newrelic_middleware_analytics'
require 'hoodoo/monkey/patch/newrelic_traced_amqp'
