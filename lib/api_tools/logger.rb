module ApiTools

  # A class intended as a standardised API/service logger. The class acts as
  # a proxy; an external logger can (and usually will) be set up through
  # ::logger=. If a logger is not set, the class will log to STDOUT with an
  # appropriate 'DEBUG', 'INFO', 'WARN' or 'ERROR' prefix.
  #
  # Custom loggers are written by implementing the same interface as the four
  # methods ::debug, ::info, ::warn and ::error described herein. Loggers just
  # take the list of arguments and log them. There is no need to check log
  # level as ApiTools only calls a custom logger if the appropriate level is
  # set.
  #
  class Logger

    @@logger = nil
    @@level  = :debug

    # Return the current logger, or `nil` if undefined. See also ::logger=.
    #
    def self.logger
      @@logger
    end

    # Set the current logger.
    #
    # +logger+:: The logger class to use (any class that implements
    #            the same interface as ::debug, ::info, ::warn and ::error).
    #
    def self.logger=(logger)
      @@logger = logger
    end

    # Return the current log level. This is +:debug+ by default. See
    # also ::level=.
    #
    def self.level
      @@level
    end

    # Set the current log level.
    #
    # +level+:: One of +:debug+, +:info+, +:warn+, +:error+. These are
    #           in order from most verbose to least. When +:debug+, all
    #           kinds of log messages will be written. When +:info+,
    #           all kinds of log messages except debug will be written.
    #           When +:warn+, all messages except debug or info will be
    #           written; when +:error+, only errors will be written.
    #
    def self.level=(level)
      @@level = level
    end

    # Write to the DEBUG log, provided the log level is +:debug+.
    # See also ::logger=.
    #
    # *args:: One or more arguments that will be treated as strings and
    #         written in the presented order to the log, each on its own
    #         line of output ("\\n" terminated).
    #
    def self.debug *args
      return unless @@level == :debug
      logger ? logger.debug(args) : $stdout.puts('DEBUG', args)
    end

    # Write to the INFO log, provided the log level is +:debug+ or +:info+.
    # See also ::logger=.
    #
    # *args:: One or more arguments that will be treated as strings and
    #         written in the presented order to the log, each on its own
    #         line of output ("\\n" terminated).
    #
    def self.info *args
      return unless @@level == :debug || @@level == :info
      logger ? logger.info(args) : $stdout.puts('INFO', args)
    end

    # Write to the INFO log, provided the log level is +:debug+, +:info+ or
    # +:warn+. See also ::logger=.
    #
    # *args:: One or more arguments that will be treated as strings and
    #         written in the presented order to the log, each on its own
    #         line of output ("\\n" terminated).
    #
    def self.warn *args
      return unless @@level == :debug || @@level == :info || @@level == :warn
      logger ? logger.warn(args) : $stdout.puts('WARN', args)
    end

    # Write to the ERROR log, regardless of logging level. See also ::logger=.
    #
    # *args:: One or more arguments that will be treated as strings and
    #         written in the presented order to the log, each on its own
    #         line of output ("\\n" terminated).
    #
    def self.error *args
      logger ? logger.error(args) : $stderr.puts('ERROR', args)
    end
  end
end
