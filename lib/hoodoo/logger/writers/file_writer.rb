########################################################################
# File::    file_writer.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Write flat log messages to a file.
# ----------------------------------------------------------------------
#           16-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo
  class Logger

    # Writes unstructured messages to a file. Hoodoo::Logger::SlowWriter
    # subclass. See also Hoodoo::Logger.
    #
    class FileWriter < Hoodoo::Logger::SlowWriter

      include Hoodoo::Logger::FlattenerMixin

      # Create a file writer instance. Files are written by opening,
      # adding a log message and closing again, to provide reliability.
      # For this reason, this is a Hoodoo::Logger::SlowWriter subclass.
      #
      # If you want faster file access at the expense of immediate updates
      # / reliability due to buffering, open a file externally to create an
      # I/O stream and pass this persistently-open file's stream to an
      # Hoodoo::Logger::StreamWriter class instead.
      #
      # +pathname+:: Full pathname of a file that can be opened in "ab"
      #              (append for writing at end-of-file) mode.
      #
      def initialize( pathname )
        @pathname = pathname
      end

      # See Hoodoo::Logger::WriterMixin#report.
      #
      def report( log_level, component, code, data )
        File.open( @pathname, 'ab' ) do | file |
          file.puts( flatten( log_level, component, code, data ) )
        end
      end
    end
  end
end
