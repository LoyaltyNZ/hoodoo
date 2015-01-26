########################################################################
# File::    slow_writer.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Base class for slow log writers.
# ----------------------------------------------------------------------
#           16-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo
  class Logger

    # Log writer classes are used through the Hoodoo::Logger class.
    #
    # Subclass SlowWriter if you are writing a log data output mechanism which
    # does not respond very quickly. File output might fall into this category
    # depending upon target deployment infrastructure; exporting logs to a
    # remote logging service over the network would certainly qualify.
    #
    # The subclass only needs to implement
    # Hoodoo::Logger::WriterMixin#report.
    #
    # If a slow writer cannot keep up with a high rate of log messages, some
    # may be dropped. A +:warn+ level message is reported automatically for
    # such cases, describing the number of dropped messages, once the slow
    # writer has caught up.
    #
    # *IMPORTANT*: If you use ActiveRecord in a slow writer class, beware that
    # your writer runs in a ruby Thread. Unless you take steps to prevent it,
    # ActiveRecord will implicitly check out a connection which stays with
    # your Thread forever. This steals a connection from the pool. To prevent
    # this issue, you must use the following pattern:
    #
    #     def report( log_level, component, code, data )
    #       ActiveRecord::Base.connection_pool.with_connection do
    #         # ...Any AciveRecord code goes here...
    #       end
    #     end
    #
    # Code within the +with_connection+ block uses a temporary connection from
    # the pool which is returned once the block has finished processing. Even
    # if exceptions occur within your ActiveRecord code, the connection is
    # still correctly returned to the pool using the above approach.
    #
    class SlowWriter
      include Hoodoo::Logger::WriterMixin
    end
  end
end
