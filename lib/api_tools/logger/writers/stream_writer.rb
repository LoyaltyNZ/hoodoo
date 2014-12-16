########################################################################
# File::    file_writer.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Write flat log messages to an I/O stream - STDOUT by
#           default.
# ----------------------------------------------------------------------
#           16-Dec-2014 (ADH): Created.
########################################################################

module ApiTools
  class Logger

    # Writes unstructured messages to (presumed) fast output streams such as
    # +$stdout+. ApiTools::Logger::FastWriter subclass. See also
    # ApiTools::Logger.
    #
    class StreamWriter < ApiTools::Logger::FastWriter

      # Create a stream writer instance. Although you could initialize this
      # class with a slow output stream, they're expected to be fast (e.g.
      # terminal output) as this is an ApiTools::Logger::FastWriter subclass.
      #
      # For reliable file writing, use the ApiTools::Logger::FileWriter class
      # instead.
      #
      # +output_stream+:: Optional I/O stream instance; default is +$stdout+.
      #                   The instance must provide a +puts+ implementation.
      #
      def initialize( output_stream = $stdout )
        @output_stream = output_stream
      end

      # See ApiTools::Logger::WriterMixin#report.
      #
      def report( log_level, component, code, data )
        @output_stream.puts(
          log_level.to_s.upcase,
          component,
          code,
          data.inspect
        )
      end
    end
  end
end
