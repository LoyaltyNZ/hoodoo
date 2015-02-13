########################################################################
# File::    exception_reporting.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Reporting exceptions to third party error management
#           services.
# ----------------------------------------------------------------------
#           08-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo; module Services
  class Middleware

    # Exception reporting / monitoring through external services.
    #
    class ExceptionReporting

      # Pool of exception reporters.
      #
      @@reporter_pool = Hoodoo::Communicators::Pool.new

      # Add an exception reporter class to the set of reporters. See the
      # Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter class for an
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
      # made but processing of other reporters continues uninterrupted. It is
      # up to individual reporter classes to manage thread safety.
      #
      # +klass+:: Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter
      #           subclass (class, not instance) to add.
      #
      def self.add( klass )
        unless klass < Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter
          raise "Hoodoo::Services::Middleware.add must be called with a Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter subclass"
        end

        @@reporter_pool.add( klass.instance )
      end

      # Remove an exception reporter class from the set of reporters. See
      # ::add for details.
      #
      # +klass+:: Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter
      #           subclass (class, not instance) to remove.
      #
      def self.remove( klass )
        unless klass < Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter
          raise "Hoodoo::Services::Middleware.remove must be called with a Hoodoo::Services::Middleware::ExceptionReporting::BaseReporter subclass"
        end

        @@reporter_pool.remove( klass.instance )
      end

      # Call all added exception reporters (see ::add) to report an exception.
      #
      # +exception+:: Exception or Exception subclass instance to report.
      #
      # +rack_env+::  Optional Rack environment hash for the inbound request,
      #               for exception reports made in the context of Rack request
      #               handling.
      #
      def self.report( exception, rack_env = nil )
        payload = Payload.new( exception: exception, rack_env: rack_env )
        @@reporter_pool.communicate( payload )
      end

      # Wait for all executing reporter threads to catch up before continuing.
      #
      # +timeout+:: Optional timeout wait delay *for* *each* *thread*. Default
      #             is 5 seconds.
      #
      def self.wait( timeout = 5 )
        @@reporter_pool.wait( per_instance_timeout: timeout )
      end

      # Implementation detail of
      # Hoodoo::Services::Middleware::ExceptionReporting used to carry
      # multiple parameters describing exception related data through the
      # Hoodoo::Communicators::Pool#communicate mechanism.
      #
      class Payload

        # Exception (or Exception subclass) instance.
        #
        attr_accessor :exception

        # Rack environment (the unprocessed, original Hash). May be +nil+.
        #
        attr_accessor :rack_env

        # Initialize this instance with named parameters:
        #
        # +exception+:: Exception (or Exception subclass) instance. Mandatory.
        # +rack_env+::  Rack environment hash. Optional.
        #
        def initialize( exception:, rack_env: nil )
          @exception = exception
          @rack_env  = rack_env
        end
      end
    end

  end
end; end
