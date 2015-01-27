########################################################################
# File::    fast_writer.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Base class for fast log writers.
# ----------------------------------------------------------------------
#           16-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo
  class Logger

    # Log writer classes are used through the Hoodoo::Logger class.
    #
    # Subclass FastWriter if you are writing a log data output mechanism which
    # responds very quickly. File output might fall into this category
    # depending upon target deployment infrastructure; printing to the console
    # would certainly qualify.
    #
    # The subclass only needs to implement
    # Hoodoo::Logger::WriterMixin#report.
    #
    class FastWriter
      include Hoodoo::Logger::WriterMixin
    end
  end
end
