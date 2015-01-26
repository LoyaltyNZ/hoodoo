########################################################################
# File::    writer_mixin.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Common code for fast and slow log writer base classes.
# ----------------------------------------------------------------------
#           16-Dec-2014 (ADH): Created.
########################################################################

module Hoodoo
  class Logger

    # This mixin is used by Hoodoo::Logger::FastWriter and
    # Hoodoo::Logger::SlowWriter. See those two classes for details.
    #
    module WriterMixin

      # Hoodoo::Logger::FastWriter and Hoodoo::Logger::SlowWriter
      # subclasses implement this method.
      #
      # Write a structured log message. Writers sending data somewhere with no
      # structure support will need to serialize/flatten the message; others
      # should retain data structures like hashes or arrays.
      #
      # The #report method is only invoked if the logging threshold level of
      # the owning logger is set to an equal or lower level. Implementations
      # do not, therefore, need to check this themselves.
      #
      # +log_level+:: Log level as a symbol - one of, from most trivial to most
      #               severe, +:debug+, +:info+, +:warn+ or +:error+.
      #
      # +component+:: Component - for example, a resource name for a specific
      #               service implementation, 'Middleware' for Hoodoo itself,
      #               or some other name you think is useful. String or Symbol.
      #
      # +code+::      Component-defined code. Think of this in a manner similar
      #               to platform error codes, appearing after the "."; messages
      #               related to the same thing should share the same code. The
      #               intent is to produce log data that someone can filter on
      #               code to get useful information about that specific aspect
      #               of a service implementation's behaviour.
      #
      # data::        A Hash containing the level, component and code-dependent
      #               payload data to be logged. Converted to a string with
      #               +inspect+ for flat output use in an unstructured context.
      #
      def report( log_level, component, code, data )
        raise( 'Subclasses must implement #report' )
      end
    end
  end
end
