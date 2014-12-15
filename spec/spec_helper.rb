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

# Include AMQEndpoint for testing only.

begin
  require 'amq-endpoint'
rescue LoadError
  raise 'Cannot load amq-endpoint; did you run me with "bundle exec..." ?'
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

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  #
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  #
  Kernel.srand config.seed

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

  # As per previous comments, redirect $stderr before each test plus various
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

# Annoyingly have to silence STDOUT chatter from ActiveRecord::Migration
# and use an 'ensure' block (see later) to make sure it gets restored.
# To do this for you, call here and pass a block where you create your
# table and associated model.
#
def spec_helper_define_model( &block )
  begin
    $old_stdout = $stdout
    $stdout     = File.open( File::NULL, 'w' )

    yield

  ensure
    $stdout = $old_stdout

  end
end

# Start up a service application under WEBrick via Rack on localhost, using
# any available free port. The server is run in a Ruby Thread and *cannot be
# killed* once started. It will only exit when the entire calling process shuts
# down.
#
# Only returns once the server is running and accepting connections. Returns
# the port number upon which the server is listening.
#
# +app_class+:: ApiTools::ServiceApplication subclass for the service to start.
#
# +use_ssl+::   If +true+, SSL self-signed certificates in +spec/files+ are
#               used to support SSL testing, provided certificate chain
#               verification is bypassed. Optional; default is +false+, which
#               uses normal HTTP.
#

require 'webrick'
require 'webrick/https'

def spec_helper_start_svc_app_in_thread_for( app_class, use_ssl = false )

  port   = ApiTools::Utilities.spare_port()
  thread = Thread.start do
    app = Rack::Builder.new do
      use ApiTools::ServiceMiddleware
      run app_class.new
    end

    options = {
      :app    => app,
      :Port   => port,
      :Host   => '127.0.0.1',
      :server => :webrick
    }

    pem = File.join( File.dirname( __FILE__ ), 'files', 'ssl.pem' )
    key = File.join( File.dirname( __FILE__ ), 'files', 'ssl.key' )

    if ( use_ssl )
      options.merge!( {
        :SSLEnable      => true,
        :SSLCertificate => OpenSSL::X509::Certificate.new( File.open( pem ).read ),
        :SSLPrivateKey  => OpenSSL::PKey::RSA.new( File.open( key ).read ),
        :SSLCertName    => [ [ "CN", WEBrick::Utils::getservername() ] ]
      } )
    end

    # This command never returns. Since this server usually brings up the
    # service application before anything else happens (dependent upon the
    # exact call order of a test, but it's always true at the time of writing),
    # this is the application which will also run a local DRb server.

    begin
      Rack::Server.start( options )
    rescue => e
      puts "TEST SERVER FAILURE: #{e.inspect}"
      puts e.backtrace
    end
  end

  # Wait for the server to come up. I tried many approaches. In the end,
  # only this hacky polling-talk-to-server code worked reliably.

  repeat = true

  while repeat
    begin
      spec_helper_http( path: '/', port: port, ssl: use_ssl )
      repeat = false
    rescue Errno::ECONNREFUSED
      sleep 0.1
    end
  end

  return port
end

# Run an HTTP request on localhost and return the result as a
# +Net::HTTP::Response+ instance.
#
# +path+::    URI path _including_ leading "/".
# +port+::    Port number (String or Integer)
# +ssl+::     (Optional) +true+ to use HTTPS, else HTTP
# +klass+::   (Optional) Class to use for request, default +Net::HTTP::Get+
# +body+::    (Optional) Body for request (POST/PATCH only), default +nil+
# +headers+:: (Optional) Header name/value Hash, default empty.
#
def spec_helper_http( path:,
                      port:,
                      ssl:     false,
                      klass:   Net::HTTP::Get,
                      body:    nil,
                      headers: {} )

  headers    = { 'Content-Type' => 'application/json; charset=utf-8' }.merge( headers )
  remote_uri = URI.parse( "http://127.0.0.1:#{ port }#{ path }" )
  http       = Net::HTTP.new( remote_uri.host, remote_uri.port )
  request    = klass.new( remote_uri.request_uri() )

  if ( ssl )
    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end

  request.initialize_http_header( headers )
  request.body = body unless body.nil?

  return http.request( request )
end
