########################################################################
# File::    slow_writer.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Base class for slow log writers.
# ----------------------------------------------------------------------
#           16-Dec-2014 (ADH): Created.
########################################################################

module ApiTools
  class Logger

    # Log writer classes are used through the ApiTools::Logger class.
    #
    # Subclass SlowWriter if you are writing a log data output mechanism which
    # does not respond very quickly. File output might fall into this category
    # depending upon target deployment infrastructure; exporting logs to a
    # remote logging service over the network would certainly qualify.
    #
    # The subclass only needs to implement
    # ApiTools::Logger::WriterMixin#report.
    #
    # If a slow writer cannot keep up with a high rate of log messages, some
    # may be dropped. A +:warn+ level message is reported automatically for
    # such cases, describing the number of dropped messages, once the slow
    # writer has caught up.
    #
    class SlowWriter
      include ApiTools::Logger::WriterMixin
    end
  end
end
