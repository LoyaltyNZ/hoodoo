module ApiTools

  # Multiple output logging via local code or external services.
  #
  class Logging

      # Set of logging instances. See ::add_logger.
      #
      @@loggers = Set.new

      # Group of processing Threads currently in use. One Thread is added
      # for each logger.
      #
      @@thread_group = ThreadGroup.new

      # Add an logger class to the set of loggers. See the
      # ApiTools::Logging::Base class for an overview.
      #
      # Whenever ApiTools logging is requested, the engine runs through its
      # set of loggers (if any) and calls each one with log information.
      #
      # Loggers are maintained in a Set. Only one class will ever be stored
      # and called once per log message; the original order of addition
      # before duplicates is maintained (so if you add class A, then B, then
      # A again, then class A is called first and only once, then B once).
      #
      # Loggers are either called inline, or from their own Ruby Thread per
      # log message if the logger requests it. If the logger raises an
      # exception, it is caught, printed to $stderr and othewise ignored. If
      # the logger is slow - for example, it forwards messages to an external
      # network-based service - then it should
      #
      # +klass+:: ApiTools::Logging::Base subclass (class, not instance) to
      #           add.
      #
      def self.add( klass )
        unless klass < ApiTools::Logging::Base
          raise "ApiTools::ServiceMiddleware.add must be called with an ApiTools::Logging::Base subclass"
        end

        @@loggers << klass.instance # Base includes Singleton
      end

      # Remove an logger class from the set of loggers. See ::add for details.
      #
      # +klass+:: ApiTools::Logging::Bass subclass (class, not instance) to
      #           remove.
      #
      def self.remove( klass )
        unless klass < ApiTools::Logging::Base
          raise "ApiTools::ServiceMiddleware.remove must be called with an ApiTools::Logging::Base subclass"
        end

        @@loggers -= [ klass.instance ] # Base includes Singleton
      end




      def self.report( log_level, component, code, data )

        return if log_level == :debug && @@level != :debug
        return if log_level == :info  && @@level != :debug && @@level != :info
        return if log_level == :warn  && @@level != :debug && @@level != :info && @@level != :warn

        if


        if @@logger && @@logger.respond_to?( :report )
          @@logger.report( log_level, component, code, data )
        elsif @@logger && @@logger.respond_to?( log_level )
          @@logger.send( log_level, component, code, data.inspect )
        else
          $stdout.puts( log_level.to_s.upcase, component, code, data.inspect )
        end
      end

      # Call all added exception reporters (see ::add) to report an exception.
      # Call the loggers in @@loggers to report an
      # exception. Each is called in its own Thread. Exceptions from the
      # loggers themselves are logged with a debug level, but otherwise
      # ignored. Any other loggers are still called. It is up to individual
      # logger classes to manage thread safety.
      #
      # +exception+:: Exception or Exception subclass instance to report.
      #
      # +rack_env+::  Optional Rack environment hash for the inbound request,
      #               for loggers made in the context of Rack request
      #               handling.
      #
      # See also ::add.
      #
      def self.report( exception, rack_env = nil )
        @@loggers.each do | logger |

          @@thread_group.add( Thread.new do
            begin
              logger.report( exception, rack_env )

            rescue => logger_exception
              # Ignore logger exceptions, apart from logging them.

              begin
                Thread.exclusive do
                  ApiTools::Logger.debug(
                    'ApiTools::ServiceMiddleware#call_loggers_with',
                    "Exception logger class #{ logger.class.name } raised exception during reporting",
                    logger_exception.to_s
                  )
                end

              rescue
                # Ignore debug log exceptions. Can't do anything about them.

              end
            end
          end ) # ")" closes "@@thread_group.add("

        end
      end

      # Wait for all executing logger threads to complete before continuing.
      #
      # +timeout+:: Optional timeout wait delay FOR EACH THEAD. Default is 10
      #             seconds.
      #
      def self.wait( timeout = 10 )
        @@thread_group.list.each do | thread |
          thread.join( timeout )
        end
      end
    end
  end
end
