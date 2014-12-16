# module ApiTools
#
#   # A class intended as a standardised API/service logger. The class acts as
#   # a proxy; an external logger can (and usually will) be set up through
#   # ::logger=. If a logger is not set, the class will log to STDOUT with an
#   # appropriate 'DEBUG', 'INFO', 'WARN' or 'ERROR' prefix.
#   #
#   # Custom loggers may be written by implementing the same interface as the
#   # methods ::debug, ::info, ::warn and ::error described herein. Loggers just
#   # take the list of arguments and log them. There is no need to check log
#   # level as ApiTools only calls a custom logger if the appropriate level is
#   # set. Do *NOT* subclass ApiTools::Logger!
#   #
#   # Alternatively, a custom logger may support structured logging through
#   # providing an implementation of the ::report method signature which
#   # preserves data structures (e.g. via a database engine). See ::report for
#   # details. If you do this, you need to _ONLY_ implement this method - flat
#   # logging methods won't be called, as they're promoted to structured entries
#   # for custom loggers that support such. As with the flat logging methods,
#   # there's no need to check log level as ApiTools does this for you.
#   #
#   class Logger
#
#     @@logger = nil
#     @@level  = :debug
#
#     # Return the current logger, or `nil` if undefined. See also ::logger=.
#     #
#     def self.logger
#       @@logger
#     end
#
#     # Set the current logger.
#     #
#     # +logger+:: The logger class to use (any class that implements
#     #            the same interface as ::debug, ::info, ::warn and ::error,
#     #            or optionally ::report). *NOT* a subclass of ApiTools::Logger!
#     #
#     def self.logger=( logger )
#       if logger.nil? || logger == ApiTools::Logger
#         @@logger = nil
#       elsif logger <= ApiTools::Logger
#         raise "Custom logger classes must not subclass ApiTools::Logger"
#       else
#         @@logger = logger
#       end
#     end
#
#     # Return the current log level. This is +:debug+ by default. See
#     # also ::level=.
#     #
#     def self.level
#       @@level
#     end
#
#     # Set the current log level.
#     #
#     # +level+:: One of +:debug+, +:info+, +:warn+, +:error+. These are
#     #           in order from most verbose to least. When +:debug+, all
#     #           kinds of log messages will be written. When +:info+,
#     #           all kinds of log messages except debug will be written.
#     #           When +:warn+, all messages except debug or info will be
#     #           written; when +:error+, only errors will be written.
#     #
#     def self.level=( level )
#       @@level = level
#     end
#
#     # Logs a message using the structured logger. If no logger is available,
#     # then log data is just dumped to $stdout. If a logger is available but
#     # does not support the structured logging ::report method, then flat
#     # logging is used instead by calling a method named according go the
#     # +level+ parameter instead.
#     #
#     # Structured logging preserves data structures like hashes or arrays
#     # rather than dumping things out as strings into flat output streams.
#     #
#     # As with flat logging methods ::debug, ::info, ::warn and ::error, a
#     # message is only logged if the logging threshold level (see ::level=) is
#     # set to an equal or lower level.
#     #
#     # +log_level+:: Log level as a symbol - one of, from most trivial to most
#     #               severe, +:debug+, +:info+, +:warn+ or +:error+.
#     #
#     # +component+:: Component. This is the resource name for a specific
#     #               service implementation, 'Middleware' for ApiTools itself,
#     #               or some other name you think is useful. String or Symbol.
#     #
#     # +code+::      Component-defined code. Think of this in a manner similar
#     #               to platform error codes, appearing after the "."; messages
#     #               related to the same thing should share the same code. The
#     #               intent is to produce log data that someone can filter on
#     #               code to get useful information about that specific aspect
#     #               of a service implementation's behaviour.
#     #
#     # data::        A Hash containing the level, component and code-dependent
#     #               payload data to be logged. Converted to a string with
#     #               +inspect+ for flat output use in an unstructured context.
#     #
#     def self.report( log_level, component, code, data )
#
#       return if log_level == :debug && @@level != :debug
#       return if log_level == :info  && @@level != :debug && @@level != :info
#       return if log_level == :warn  && @@level != :debug && @@level != :info && @@level != :warn
#
#       if @@logger && @@logger.respond_to?( :report )
#         @@logger.report( log_level, component, code, data )
#       elsif @@logger && @@logger.respond_to?( log_level )
#         @@logger.send( log_level, component, code, data.inspect )
#       else
#         $stdout.puts( log_level.to_s.upcase, component, code, data.inspect )
#       end
#     end
#
#     # Write to the DEBUG log, provided the log level is +:debug+.
#     # See also ::logger=.
#     #
#     # The logging data is unstructured, but gets passed to ::report for
#     # structured logging under component 'Middleware' and code 'log'.
#     # Calling ::report is recommended over unstructured direct logging.
#     #
#     # *args:: One or more arguments that will be treated as strings and
#     #         written in the presented order to the log, each on its own
#     #         line of output ("\\n" terminated).
#     #
#     def self.debug( *args )
#       self.report( :debug, :Middleware, :log, { '_data' => args } )
#     end
#
#     # Write to the INFO log, provided the log level is +:debug+ or +:info+.
#     # See also ::logger=.
#     #
#     # The logging data is unstructured, but gets passed to ::report for
#     # structured logging under component 'Middleware' and code 'log'.
#     # Calling ::report is recommended over unstructured direct logging.
#     #
#     # *args:: One or more arguments that will be treated as strings and
#     #         written in the presented order to the log, each on its own
#     #         line of output ("\\n" terminated).
#     #
#     def self.info( *args )
#       self.report( :info, :Middleware, :log, { '_data' => args } )
#     end
#
#     # Write to the INFO log, provided the log level is +:debug+, +:info+ or
#     # +:warn+. See also ::logger=.
#     #
#     # The logging data is unstructured, but gets passed to ::report for
#     # structured logging under component 'Middleware' and code 'log'.
#     # Calling ::report is recommended over unstructured direct logging.
#     #
#     # *args:: One or more arguments that will be treated as strings and
#     #         written in the presented order to the log, each on its own
#     #         line of output ("\\n" terminated).
#     #
#     def self.warn( *args )
#       self.report( :warn, :Middleware, :log, { '_data' => args } )
#     end
#
#     # Write to the ERROR log, regardless of logging level. See also ::logger=.
#     #
#     # The logging data is unstructured, but gets passed to ::report for
#     # structured logging under component 'Middleware' and code 'log'.
#     # Calling ::report is recommended over unstructured direct logging.
#     #
#     # *args:: One or more arguments that will be treated as strings and
#     #         written in the presented order to the log, each on its own
#     #         line of output ("\\n" terminated).
#     #
#     def self.error( *args )
#       self.report( :error, :Middleware, :log, { '_data' => args } )
#     end
#   end
# end
