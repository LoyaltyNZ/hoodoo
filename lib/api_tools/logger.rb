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
      logger ? logger.debug(args) : $stdout.puts(args)
    end

    def self.info *args
      logger ? logger.info(args) : $stdout.puts(args)
    end

    def self.error *args
      logger ? logger.error(args) : $stderr.puts(args)
    end

  end
end
