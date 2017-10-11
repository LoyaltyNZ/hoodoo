########################################################################
# File::    logger.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Override NewRelic 'new_relic/agent/logger'. See the
#           top level 'spec/newrelic_rpm.rb' file for details.
# ----------------------------------------------------------------------
#           04-Aug-2017 (ADH): Created.
########################################################################

require 'logger'

# Note that all of this will be defined when the test suite is starting up, but
# during test runs, local redefinitions of NewRelic and *undefinitions* of that
# constant will occur. The code only exists so that other "require"s will work
# and thus provide coverage, mainly inside "newrelic_middleware_analytics.rb".
#
module NewRelic
  module Agent
    def self.logger
      Logger.new( File::NULL )
    end
  end
end
