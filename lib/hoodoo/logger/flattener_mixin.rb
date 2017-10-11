########################################################################
# File::    flattener_mixin.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Common code for fast and slow log writer base classes.
# ----------------------------------------------------------------------
#           19-Dec-2014 (ADH): Created.
########################################################################

require 'time'

module Hoodoo
  class Logger

    # This mixin is used by custom logger subclasses and defines a single
    # method, Hoodoo::Logger::FlattenerMixin#flatten, which takes
    # structured log data and turns it into a single line of output
    # including ISO 8601 time and date in local server time zone (since
    # that makes log analysis easier for humans working in non-UTC time
    # zone regions).
    #
    # Using this is of course entirely optional, but if you do use it, you
    # will be ensuring consistent non-structured log output across any
    # non-structured writers.
    #
    module FlattenerMixin

      # Take the parameters from Hoodoo::Logger::WriterMixin#report and
      # return a single line string representing the "flattened" log data.
      #
      def flatten( log_level, component, code, data )
        "#{ log_level.to_s.upcase } [#{ Hoodoo::Utilities.standard_datetime( Time.now ) }] #{ component } - #{ code }: #{ data.inspect }"
      end
    end
  end
end
