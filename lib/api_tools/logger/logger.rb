########################################################################
# File::    logger.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Multiple output logging via local code or external services.
# ----------------------------------------------------------------------
#           16-Dec-2014 (ADH): Created.
########################################################################

module ApiTools

  # Multiple output logging via local code or external services. Instantiate
  # a new Logger, then use #add to add _instances_ of writer classes to the
  # collection of log writers. When #report, #debug, #info, #warn or #error
  # are called, a corresponding log message is sent once to each of the
  # writers, provided that the configured logging level (#level, #level=)
  # allows it.
  #
  # By default, a new logger instance has no configured writers so logged
  # messages will not go anywhere. You must use #add to add at least one
  # writer for the instance to be useful.
  #
  # Some writer classes are provided by ApiTools, including:
  #
  # * ApiTools::Logger::StreamWriter - write to output streams, typically
  #   expected to be fast, e.g. unredirected $stdout or $stderr.
  #
  # * ApiTools::Logger::FileWriter - write to files, typically expected to
  #   be relatively slow.
  #
  # Some loggers can preserve structural logged data (see #report) while others
  # flatten all log messages. For example, ApiTools::Logger::StreamWriter must
  # flatten messages but a custom writer that, say, persisted messages in a
  # database should be able to preserve structure.
  #
  # Writers are either considered fast or slow. Fast writers are called inline
  # as soon as a message gets logged. Slow writers are called asynchronously
  # via a Thread. A Queue is used to buffer messages for slow writers; if this
  # gets too large, messages may be dropped. Once the slow writer catches up,
  # a +warn+ level log message is automatically logged to report the number of
  # dropped messages in the interim.
  #
  # To create a new custom writer class of any name/namespace, just subclass
  # ApiTools::Logger::FastWriter or ApiTools::Logger::SlowWriter - see those
  # classes for details.
  #
  class Logger

    # Create a new logger instance. Once created, use #add to add writers.
    #
    # +component+:: Flat logging methods (see #debug, #info, #warn and #error)
    #               are internally logged through the structured logger (see
    #               #report) using the +component+ (again, see #report)
    #               optionally passed here as a Symbol or String. Default is
    #               +:Middleware+.
    #
    def initialize( component = :Middleware )
      @level     = :debug
      @pool      = ApiTools::Communicators::Pool.new
      @component = component
      @writers   = {}
    end

    # Add a new writer instance to this logger. Example:
    #
    #     file_writer   = ApiTools::Logger::FileWriter.new( 'output.log' )
    #     stdout_writer = ApiTools::Logger::StreamWriter.new
    #
    #     @logger = ApiTools::Logger.new
    #
    #     logger.add( file_writer   )
    #     logger.add( stdout_writer )
    #
    #     # ...then later...
    #
    #     logger.report( ... ) # -> Sends to "output.log" and $stdout
    #
    # +writer_instance+:: An _instance_ of a subclass of
    #                     ApiTools::Logger::FastWriter or
    #                     ApiTools::Logger::SlowWriter.
    #
    def add( writer_instance )
      communicator = if writer_instance.is_a?( ApiTools::Logger::FastWriter )
        FastCommunicator.new( writer_instance, self )
      elsif writer_instance.is_a?( ApiTools::Logger::SlowWriter )
        SlowCommunicator.new( writer_instance, self )
      else
        raise "ApiTools::Logger\#add: Only instances of ApiTools::Logger::FastWriter or ApiTools::Logger::SlowWriter can be added - #{ writer_instance.class.name } was given"
      end

      @pool.add( communicator )
      @writers[ writer_instance ] = communicator
    end

    # Remove a writer instance from this logger. If the instance has not been
    # previously added, no error is raised.
    #
    # Slow writers may take a while to finish processing and shut down in
    # the background. As a result, this method might take a while to return.
    # Internal default timeouts may even mean that the writer is still running
    # (possibly entirely hung).
    #
    # +writer_instance+:: An _instance_ of a subclass of
    #                     ApiTools::Logger::FastWriter or
    #                     ApiTools::Logger::SlowWriter.
    #
    def remove( writer_instance )
      communicator = @writers[ writer_instance ]
      @pool.remove( communicator ) unless communicator.nil?
    end

    # Remove all writer instances from this logger.
    #
    # Slow writers may take a while to finish processing and shut down in
    # the background. As a result, this method might take a while to return.
    # Internal default timeouts may even mean that one or more slow writers
    # are still running (possibly entirely hung).
    #
    def remove_all
      @pool.terminate()
      @writers = {}
    end

    # Wait for all writers to finish writing all log messages sent up to the
    # point of calling. Internal default timeouts for slow writers mean that
    # hung or extremely slow/backlogged writers may not have finished by the
    # time the call returns, but it's necessary to enforce a timeout else
    # this call may never return at all.
    #
    def wait
      @pool.wait()
    end

    # Return or set the current log level. This is +:debug+ by default.
    #
    attr_accessor :level

    # Given the log level configuration of this instance - see #level= and
    # #level - should a message of the given log level be reported? Returns
    # +true+ if so else +false+.
    #
    # This is mostly for internal use but external callers might find it
    # useful from time to time, especially in tests.
    #
    # +log_level+:: Log level of interest as a Symbol - +debug+, +info+, +warn+
    #               or +error+.
    #
    def report?( log_level )
      return false if log_level == :debug && @level != :debug
      return false if log_level == :info  && @level != :debug && @level != :info
      return false if log_level == :warn  && @level != :debug && @level != :info && @level != :warn
      return true
    end

    # Logs a message using the structured logger. Whether or not log data is
    # written in a stuctured manner depends upon the writer(s) in use (see
    # #add). Structured writers preserve data structures like hashes or arrays
    # rather than (say) dumping things out as strings into flat output streams.
    #
    # As with flat logging methods #debug, #info, #warn and #error, a
    # message is only logged if the logging threshold level (see #level=) is
    # set to an equal or lower level.
    #
    # +log_level+:: Log level as a symbol - one of, from most trivial to most
    #               severe, +:debug+, +:info+, +:warn+ or +:error+.
    #
    # +component+:: Component; for example, the resource name for a specific
    #               resource endpoint implementation, 'Middleware' for ApiTools
    #               middleware itself, or some other name you think is useful.
    #               String or Symbol.
    #
    # +code+::      Component-defined code. Think of this in a manner similar
    #               to platform error codes, appearing after the "."; messages
    #               related to the same thing should share the same code. The
    #               intent is to produce log data that someone can filter on
    #               code to get useful information about that specific aspect
    #               of a service implementation's behaviour.
    #
    # data::        A Hash containing the level-, component- and code-dependent
    #               payload data to be logged.
    #
    def report( log_level, component, code, data )
      return unless self.report?( log_level )

      @pool.communicate(
        Payload.new(
          log_level,
          component,
          code,
          data
        )
      )
    end

    # Write a +debug+ log message, provided the log level is +:debug+.
    #
    # The logging data is unstructured, but gets passed to #report for
    # structured logging under the component specified in the constructor
    # and code 'log'.
    #
    # Calling ::report is recommended over unstructured direct logging.
    #
    # *args:: One or more arguments that will be treated as strings and
    #         written in the presented order to the log, each on its own
    #         line of output ("\\n" terminated).
    #
    def debug( *args )
      self.report( :debug, @component, :log, { '_data' => args } )
    end

    # Write an +info+ log message, provided the log level is +:debug+ or
    # +:info+.
    #
    # The logging data is unstructured, but gets passed to #report for
    # structured logging under the component specified in the constructor
    # and code 'log'.
    #
    # Calling ::report is recommended over unstructured direct logging.
    #
    # *args:: One or more arguments that will be treated as strings and
    #         written in the presented order to the log, each on its own
    #         line of output ("\\n" terminated).
    #
    def info( *args )
      self.report( :info, @component, :log, { '_data' => args } )
    end

    # Write a +warn+ log message, provided the log level is +:debug+,
    # +:info+ or +:warn+.
    #
    # The logging data is unstructured, but gets passed to #report for
    # structured logging under the component specified in the constructor
    # and code 'log'.
    #
    # Calling ::report is recommended over unstructured direct logging.
    #
    # *args:: One or more arguments that will be treated as strings and
    #         written in the presented order to the log, each on its own
    #         line of output ("\\n" terminated).
    #
    def warn( *args )
      self.report( :warn, @component, :log, { '_data' => args } )
    end

    # Write an +error+ log message, regardless of logging level.
    #
    # The logging data is unstructured, but gets passed to #report for
    # structured logging under the component specified in the constructor
    # and code 'log'.
    #
    # Calling ::report is recommended over unstructured direct logging.
    #
    # *args:: One or more arguments that will be treated as strings and
    #         written in the presented order to the log, each on its own
    #         line of output ("\\n" terminated).
    #
    def error( *args )
      self.report( :error, @component, :log, { '_data' => args } )
    end

    # Used internally toommunicate details of a log message across the
    # ApiTools::Communicators::Pool mechanism and through to a log writer.
    # Log writer authors do not need to use this class;
    # ApiTools::Logger::WriterMixin unpacks it and calls your subclass's
    # #report implementation with individual parameters for you.
    #
    class Payload

      # Log level - see ApiTools::Logger#report.
      #
      attr_reader :log_level

      # Component - see ApiTools::Logger#report.
      #
      attr_reader :component

      # Code - see ApiTools::Logger#report.
      #
      attr_reader :code

      # Data - see ApiTools::Logger#report.
      #
      attr_reader :data

      # Create an instance. Named parameters are:
      #
      # +log_level+:: See ApiTools::Logger#report.
      # +component+:: See ApiTools::Logger#report.
      # +code+::      See ApiTools::Logger#report.
      # +data+::      See ApiTools::Logger#report.
      #
      def initialize( log_level:, component:, code:, data: )
        @log_level = log_level
        @component = component
        @code      = code
        @data      = data
      end
    end

    # Mixin used internally for the FastCommunicator and SlowCommunicator
    # wrappers that hide implementation complexity from log writer subclasses.
    #
    module Communicator
      def initialize( writer_instance, owning_logger )
        @writer_instance = writer_instance
        @owning_logger   = owning_logger
      end

      # Implement ApiTools::Communicators::Base#communicate for both slow and
      # fast writers. Assumes it will be passed an ApiTools::Logger::Payload
      # class instance which describes the structured log data to report; also
      # assumes it is only called when the calling logger's configured log
      # level threshold should allow through the level of the log message in
      # question. Calls through to the #report implementation.
      #
      def communicate( payload )
        @writer_instance.report(
          payload.log_level,
          payload.component,
          payload.code,
          payload.data
        )
      end

      # Implement optional method ApiTools::Communicators::Slow#dropped on
      # behalf of subclasses. The method turns the 'messages dropped'
      # notification into a log message of +:warn+ level and which it reports
      # internally immediately for the Writer instance only (since different
      # writers have different queues and thus different dropped message
      # warnings), provided that the owning ApiTools::Logger instance log
      # level lets warnings through.
      #
      def dropped( number )
        if @owning_logger.report?( :warn )
          @writer_instance.report(
            :warn,
            self.class.name,
            'dropped.messages',
            "Logging flooded - #{ number } messages dropped"
          )
        end
      end
    end

    # Used internally as an ApiTools::Communicator::Pool communicator wrapping
    # fast log writer instances.
    #
    class FastCommunicator < ApiTools::Communicators::Fast
      include Communicator
    end

    # Used internally as an ApiTools::Communicator::Pool communicator wrapping
    # slow log writer instances.
    #
    class SlowCommunicator < ApiTools::Communicators::Slow
      include Communicator
    end

  end
end
