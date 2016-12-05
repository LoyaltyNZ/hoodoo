########################################################################
# File::    method_tracer.rb
# (C)::     Loyalty New Zealand 2016
#
# Purpose:: Override NewRelic 'new_relic/agent/method_tracer'. See the
#           top level 'spec/newrelic_rpm.rb' file for details.
# ----------------------------------------------------------------------
#           02-Dec-2016 (ADH): Created.
########################################################################

# Note that all of this will be defined when the test suite is starting up, but
# during test runs, local redefinitions of NewRelic and *undefinitions* of that
# constant will occur. The code only exists so that other "require"s will work
# and thus provide coverage, mainly inside "newrelic_middleware_analytics.rb".
#
module NewRelic
  module Agent
    module MethodTracer

      def self.included( klass )
        klass.extend( ClassMethods )
      end

      module ClassMethods
        module AddMethodTracer
          def add_method_tracer( method_name, metric_name_code = nil, options = {} )
          end
        end

        include AddMethodTracer
      end

    end
  end
end
