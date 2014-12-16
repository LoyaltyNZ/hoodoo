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

    # Writes unstructured messages to a file. ApiTools::Logger::SlowWriter
    # subclass. See also ApiTools::Logger.
    #
    class FileWriter < ApiTools::Logger::SlowWriter

      # Create a file writer instance. Files are written by opening,
      # adding a log message and closing again, to provide reliability.
      # For this reason, this is an ApiTools::Logger::SlowWriter subclass.
      #
      # If you want faster file access at the expense of immediate updates
      # / reliability due to buffering, open a file externally to create an
      # I/O stream and pass this persistently-open file's stream to an
      # ApiTools::Logger::StreamWriter class instead.
      #
      # +pathname+:: Full pathname of a file that can be opened in "ab"
      #              (append for writing at end-of-file) mode.
      #
      def initialize( pathname )
        @pathname = pathname
      end

      # See ApiTools::Logger::WriterMixin#report.
      #
      def report( log_level, component, code, data )
        File.open( @pathname, 'ab' ) do | file |
          file.puts(
            log_level.to_s.upcase,
            component,
            code,
            data.inspect
          )
        end
      end
    end
  end
end
