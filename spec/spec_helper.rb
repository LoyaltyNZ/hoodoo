# Set the correct environment for testing
ENV[ 'RACK_ENV' ] = 'test'

# Configure the code coverage analyser.

require 'simplecov'
require 'simplecov-rcov'

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter '_spec'
end

require 'rack/test'
require 'api_tools'

RSpec.configure do | config |

  # Provides familiar-ish 'get'/'post' etc. DSL for simulated URL fetch tests.

  config.include Rack::Test::Methods

  # http://stackoverflow.com/questions/1819614/how-do-i-globally-configure-rspec-to-keep-the-color-and-format-specdoc-o
  #
  # Use color in STDOUT,
  # use color not only in STDOUT but also in pagers and files.
  #
  config.color = true
  config.tty   = true

  # The normal logger logs to stdout and stderr - stderr output can be useful
  # in real tests but pollutes visual test output. Redirect it. "#error" calls
  # to the ApiTools logger will end up in the log.

  class StdErrTestLogger
    def self.debug *args
      $stderr.puts('DEBUG',args)
    end
    def self.info *args
      $stderr.puts('INFO',args)
    end
    def self.warn *args
      $stderr.puts('WARN',args)
    end
    def self.error *args
      $stderr.puts('ERROR',args)
    end
  end

  # There used to be a logger_spec.rb test to make sure that the initial logger
  # value is nil, but we can't do that when we're using a stderr test logger.
  # So, instead, throw an exception here if that fails and use an updated test
  # in logger_spec.rb that expects to find the test logger we assign instead.

 # raise "Unexpected logging configuration" unless ApiTools::Logger.logger.nil?

  config.before( :all ) do
    log = File.new( 'test.log', 'a+')
    $stderr.reopen(log)

    $stderr << "\n" << "*"*80 << "\n"
    $stderr << Time.now.to_s << "\n"
    $stderr << "*"*80 << "\n\n"

    ApiTools::Logger.logger = StdErrTestLogger
    ApiTools::ServiceSession.testing true
  end

  # Session test mode - test mode disabled explicitly for session tests

  config.after( :all ) do
    ApiTools::Logger.logger = ApiTools::Logger
    ApiTools::ServiceSession.testing false
  end
end
