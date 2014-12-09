module ApiTools
  class ServiceMiddleware

    # Exception reporting / monitoring through external services.
    #
    class ExceptionReporting

      # Set of exception reporting instances. See ::add_exception_reporter.
      #
      @@exception_reporters = Set.new

      # Group of processing Threads currently in use.
      #
      @@thread_group = ThreadGroup.new

      # Add an exception reporter class to the set of reporters. See the
      # ApiTools::ServiceMiddleware::ExceptionReporting::Base class for an
      # overview.
      #
      # Whenever the middleware's own exception handler catches an exception,
      # it will run through the set of exception reporters (if any) and call
      # each one to report exception details.
      #
      # Reporters are maintained in a Set. Only one class will ever be
      # stored and called once per exception; the original order of addition
      # before duplicates is maintained (so if you add class A, then B, then
      # A again, then class A is called first and only once, then B once).
      #
      # Each reporter is called from its own Ruby Thread so that client API
      # call response is kept fast. If a call fails, a debug log entry is
      # made but processing of other reporters continues uninterrupted.
      #
      # +klass+:: ApiTools::ServiceMiddleware::ExceptionReporting::Base
      #           subclass (class, not instance) to add.
      #
      def self.add( klass )
        unless klass < ApiTools::ServiceMiddleware::ExceptionReporting::Base
          raise "ApiTools::ServiceMiddleware.add must be called with an ApiTools::ServiceMiddleware::ExceptionReporting::Base subclass"
        end

        @@exception_reporters << klass.instance # Base includes Singleton
      end

      # Remove an exception reporter class from the set of reporters. See
      # ::add for details.
      #
      #
      # +klass+:: ApiTools::ServiceMiddleware::ExceptionReporting::Base
      #           subclass (class, not instance) to remove.
      #
      def self.remove( klass )
        unless klass < ApiTools::ServiceMiddleware::ExceptionReporting::Base
          raise "ApiTools::ServiceMiddleware.remove must be called with an ApiTools::ServiceMiddleware::ExceptionReporting::Base subclass"
        end

        @@exception_reporters -= [ klass.instance ] # Base includes Singleton
      end

      # Call the exception reporters in @@exception_reporters to report an
      # exception. Each is called in its own Thread. Exceptions from the
      # reporters themselves are logged with a debug level, but otherwise
      # ignored. Any other reporters are still called. It is up to individual
      # reporter classes to manage thread safety.
      #
      # +exception+:: Exception or Exception subclass instance to report.
      #
      # +rack_env+::  Optional Rack environment hash for the inbound request,
      #               for exception reports made in the context of Rack request
      #               handling.
      #
      # See also ::add.
      #
      def self.report( exception, rack_env = nil )
        @@exception_reporters.each do | reporter |

          @@thread_group.add( Thread.new do
            begin
              reporter.report( exception, rack_env )

            rescue => reporter_exception
              # Ignore reporter exceptions, apart from logging them.

              begin
                Thread.exclusive do
                  ApiTools::Logger.debug(
                    'ApiTools::ServiceMiddleware#call_exception_reporters_with',
                    "Exception reporter class #{ reporter.class.name } raised exception during reporting",
                    reporter_exception.to_s
                  )
                end

              rescue
                # Ignore debug log exceptions. Can't do anything about them.

              end
            end
          end ) # ")" closes "@@thread_group.add("

        end
      end

      # Wait for all executing reporter threads to complete before continuing.
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
