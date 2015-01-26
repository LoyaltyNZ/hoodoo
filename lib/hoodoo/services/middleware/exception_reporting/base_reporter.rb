########################################################################
# File::    base.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Abstracted links to third party error management services.
# ----------------------------------------------------------------------
#           08-Dec-2014 (ADH): Created.
########################################################################

require 'singleton'

module Hoodoo; module Services
  class Middleware

    class ExceptionReporting

      # Subclass this method to create a custom class used to contact external
      # exception monitoring / reporting engine. Examples include:
      #
      # * Raygun:      https://raygun.io
      # * Honeybadger: https://www.honeybadger.io
      # * Exceptional: http://www.exceptional.io
      # * Airbrake:    https://airbrake.io
      #
      # Hoodoo includes some classes for integration which you can choose from
      # if you want to use the integrated service. Alternatively write your own.
      # When you do this, name your class *outside* the Hoodoo namespace (the
      # class's name can be anything you like). Otherwise you will trample upon
      # Hoodoo' reserved namespace and may cause a naming collision in future
      # Hoodoo versions.
      #
      # "Under the hood" the Hoodoo::Communicators::Pool mechanism is used.
      # All reporters are assumed to be (comparatively) slow communicators so
      # are descendants of Hoodoo::Communicators::Slow.
      #
      # Add a reporter class to the middleware from any service application by
      # calling Hoodoo::Services::Middleware::ExceptionReporting.add.
      #
      class BaseReporter < Hoodoo::Communicators::Slow

        include ::Singleton

        # Subclasses implement this method. The middleware creates the singleton
        # instance of the subclass, then calls your implementation of the method
        # when it catches an exception in its top level handler. The subclass
        # implementation sends details of the exception to the desired exception
        # monitoring or reporting service. The return value is ignored.
        #
        # The middleware wraps calls to your subclass in a nested exception
        # handler. If you raise an exception, the middleware logs details with
        # a +:debug+ level through its logger instance if possible (see
        # Hoodoo::Services::Middleware::logger) along with printing details to
        # $stderr, then continues processing.
        #
        # If service applications are expecting potential exceptions to occur
        # and they catch them without re-raising for the middleware to catch,
        # this reporting method will not be called. If a service author thinks
        # such an exception ought to be logged, they must re-raise it.
        #
        # The middleware runs calls here in a processing Thread to avoid delays
        # to the calling client. This means your implementation of this method
        # can use blocking network calls should you so wish; but beware, you are
        # running in your own Thread on every call and more than one call might
        # be running concurrently. If your implementation is not threadsafe,
        # use a Mutex. For example, add a mutex class variable to your class:
        #
        #     @@mutex = Mutex.new
        #
        # ...then use it inside +report+ with something like:
        #
        #     def report( e )
        #       @@mutex.synchronize do
        #         # Your reporting service's custom code goes here
        #       end
        #     end
        #
        # +e+::   Exception (or subclass) instance to be reported.
        #
        # +env+:: Optional Rack environment hash for the inbound request, for
        #         exception reports made in the context of Rack request
        #         handling.
        #
        def report( e, env = nil )
          raise( 'Subclasses must implement #report' )
        end

        # Subclasses *MUST* *NOT* override this method, which is part of the
        # base class implementation and implements
        # Hoodoo::Communicators::Slow#communicate. It calls through to the
        # #report method which subclasses do implement, unpacking a payload
        # used for the internal communicators into the parameters that
        # #report expects.
        #
        # +object+:: Hoodoo::Services::Middleware::ExceptionReporting::Payload
        #            instance.
        #
        def communicate( object )
          self.report( object.exception, object.rack_env )
        end
      end

    end

  end
end; end
