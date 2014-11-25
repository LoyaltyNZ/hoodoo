# Set the correct environment for testing
ENV[ 'RACK_ENV' ] = 'test'

# Configure the code coverage analyser.

require 'simplecov'
require 'simplecov-rcov'

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter '_spec'
end

# The ActiveRecord extensions need testing in the context of a database. I
# did consider NullDB - https://github.com/nulldb/nulldb - but this was too
# far from 'the real thing' for my liking. Instead, we use SQLite in memory
# and DatabaseCleaner to reset state between tests.
#
# http://stackoverflow.com/questions/7586813/fake-an-active-record-model-without-db

require 'database_cleaner'
require 'active_record'
require 'logger'

# Since AMQEndpoint is optional, we have to run without it; since files are
# parsed in the context of whether or not it is defined, we have to define a
# fake AMQEndpoint message class here for later test use.

module AMQEndpoint
  class Message
    def initialize( options ); end
    def serialize; @content; end
    def deserialize; end
  end
end

# Now it's safe to require Rack test code and APITools itself.

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

  # Wake up ActiveRecord and DatabaseCleaner.

  ActiveRecord::Base.logger = Logger.new( STDERR ) # See redirection code below
  ActiveRecord::Base.establish_connection(
    :adapter  => 'sqlite3',
    :database => ':memory:'
  )

  DatabaseCleaner.strategy = :transaction # MUST NOT be changed

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
  # Moreover, the middleware assigns its structured logger... So check for that
  # now as a prerequisite.

  raise "Unexpected logging configuration" unless ApiTools::Logger.logger == ApiTools::ServiceMiddleware::StructuredLogger

  # As per previous comments, redirect STDERR before each test plus various
  # other before/after stuff related to sessions, databases and so-on.

  config.before( :all ) do
    log = File.new( 'test.log', 'a+')
    $stderr.reopen(log)

    $stderr << "\n" << "*"*80 << "\n"
    $stderr << Time.now.to_s << "\n"
    $stderr << "*"*80 << "\n\n"

    ApiTools::Logger.logger = StdErrTestLogger
    ApiTools::Logger.level  = :debug

    ApiTools::ServiceSession.testing true
  end

  # Session test mode - test mode disabled explicitly for session tests.

  config.after( :all ) do
    ApiTools::Logger.logger = ApiTools::Logger
    ApiTools::Logger.level  = :debug

    ApiTools::ServiceSession.testing false
  end

  # Make sure DatabaseCleaner runs between each test.

  config.before( :each ) do
    DatabaseCleaner.start
  end

  config.after( :each ) do
    DatabaseCleaner.clean
  end
end
