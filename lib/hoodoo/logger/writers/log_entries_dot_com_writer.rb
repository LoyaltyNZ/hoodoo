########################################################################
# File::    log_entries_dot_com_writer.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Write structured log messages logentries.com.
# ----------------------------------------------------------------------
#           08-Jan-2015 (ADH): Created.
########################################################################

require 'json'

module Hoodoo
  class Logger

    begin          # Exception handler as 'r7_insight' gem inclusion is optional.
      require 'r7_insight' # Might raise LoadError; that's allowed.

      # Writes structured messages to Rapid7 via the "r7_insight" gem,
      # which uses its own asynchronous worker thread for network data.
      # Thus, a Hoodoo::Logger::FastWriter subclass. See also
      # Hoodoo::Logger.
      #
      class LogEntriesDotComWriter < Hoodoo::Logger::FastWriter

        # Create a log writer instance.
        #
        # +token+:: Your logentries.com API token.
        #
        def initialize( token )
          @@logger ||= R7Insight.new( token, 'eu', :ssl => true )
        end

        # See Hoodoo::Logger::WriterMixin#report.
        #
        def report( log_level, component, code, data )
          method = case log_level
            when :debug, :info, :warn, :error
              log_level
            else
              :unknown
          end

          message = {
            :level     => log_level,
            :component => component,
            :code      => code,
            :data      => data
          }

          # This method is only called if the log level set elsewhere
          # is already appropriate; always make sure that the 'LE' class
          # logging level is as low as possible so it doesn't filter any
          # additional messages accidentally.

          @@logger.level = ::Logger::DEBUG
          @@logger.send( method, ::JSON.generate( message ) )
        end
      end

    rescue LoadError # From "require 'r7_insight'"
    end

  end
end
