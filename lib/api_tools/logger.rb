module ApiTools
  # A class intended as a standardised API/service logger. The class acts as a proxy,
  # an external logger can be set in the class. If a logger is not set, the class will 
  # log to STDOUT with an appropriate 'DEBUG', 'INFO', 'WARN' or 'ERROR' prefix.
  class Logger

    @@logger  = nil
    @@level  = :debug

    # Return the current logger, or `nil` if undefined.
    def self.logger
      @@logger
    end

    # Set the current logger. 
    # Params:
    # +logger+:: The logger to use.
    def self.logger=(logger)
      @@logger = logger
    end

    def self.level
      @@level
    end

    def self.level=(level)
      @@level = level
    end

    # Write to the DEBUG log. 
    def self.debug *args
      return unless @@level == :debug 
      logger ? logger.debug(args) : $stdout.puts('DEBUG',args)
    end

    # Write to the INFO log.   
    def self.info *args
      return unless @@level == :debug || @@level == :info
      logger ? logger.info(args) : $stdout.puts('INFO',args)
    end

    # Write to the WARN log.  
    def self.warn *args
      return unless @@level == :debug || @@level == :info || @@level == :warn
      logger ? logger.warn(args) : $stdout.puts('WARN',args)
    end

    # Write to the ERROR log.
    def self.error *args
      logger ? logger.error(args) : $stderr.puts('ERROR',args)
    end

  end
end
