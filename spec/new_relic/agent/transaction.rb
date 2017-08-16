########################################################################
# File::    transaction.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Override NewRelic 'new_relic/agent/transaction'. See the
#           top level 'spec/newrelic_rpm.rb' file for details.
# ----------------------------------------------------------------------
#           07-Aug-2017 (ADH): Created.
########################################################################

# Note that all of this will be defined when the test suite is starting up, but
# during test runs, local redefinitions of NewRelic and *undefinitions* of that
# constant will occur. The code only exists so that other "require"s will work
# and thus provide coverage, mainly inside "newrelic_middleware_analytics.rb".
#
module NewRelic
  module Agent
    class Transaction

      class Segment
        def add_request_headers( request ); end
        def read_response_headers( request ); end
        def finish(); end
      end

      def self.start_external_request_segment( type, uri, method )
        return Segment.new
      end

    end
  end
end
