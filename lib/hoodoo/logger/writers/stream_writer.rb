########################################################################
# File::    file_writer.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Write flat log messages to an I/O stream - STDOUT by
#           default.
# ----------------------------------------------------------------------
#           16-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo
  class Logger

    # Writes unstructured messages to (presumed) fast output streams such as
    # +$stdout+. Hoodoo::Logger::FastWriter subclass. See also
    # Hoodoo::Logger.
    #
    class StreamWriter < Hoodoo::Logger::FastWriter

      include Hoodoo::Logger::FlattenerMixin

      # Create a stream writer instance. Although you could initialize this
      # class with a slow output stream, they're expected to be fast (e.g.
      # terminal output) as this is an Hoodoo::Logger::FastWriter subclass.
      #
      # For reliable file writing, use the Hoodoo::Logger::FileWriter class
      # instead.
      #
      # +output_stream+:: Optional I/O stream instance; default is +$stdout+.
      #                   The instance must provide a +puts+ implementation.
      #
      def initialize( output_stream = $stdout )
        @output_stream = output_stream
      end

      # See Hoodoo::Logger::WriterMixin#report.
      #
      def report( log_level, component, code, data )
        @output_stream.puts( flatten( log_level, component, code, data ) )
      end
    end
  end
end
