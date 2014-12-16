########################################################################
# File::    file_writer.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Write flat log messages to a file.
# ----------------------------------------------------------------------
#           16-Dec-2014 (ADH): Created.
########################################################################

module ApiTools
  class Logger
    class FileWriter < ApiTools::Logger::SlowWriter
      def report( log_level, component, code, data )
      end
    end
  end
end
