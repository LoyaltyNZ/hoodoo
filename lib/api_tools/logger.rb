module ApiTools
  class Logger

    @@logger  = nil

    def self.logger
      @@logger
    end

    def self.logger=(v)
      @@logger = v
    end

    def self.debug *args
      logger ? logger.debug(args) : $stdout.puts('DEBUG',args)
    end
    def self.info *args
      logger ? logger.info(args) : $stdout.puts('INFO',args)
    end

    def self.warn *args
      logger ? logger.warn(args) : $stdout.puts('WARN',args)
    end

    def self.error *args
      logger ? logger.error(args) : $stderr.puts('ERROR',args)
    end

  end
end
