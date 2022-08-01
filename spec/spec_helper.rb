require 'webrick'
require 'webrick/https'

# Set the correct environment for testing.

ENV[ 'RACK_ENV' ] = 'test'

# Configure the code coverage analyser.

require 'simplecov'
require 'simplecov-rcov'

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter '/spec/'
end

# Debugging support.

require 'byebug'

# Stubbing Net::HTTP with WebMock - disabled by default via "before :suite"
# later; only enable for tests where needed, as real Net::HTTP connections
# are used in many other tests and must not be mocked.
#
# https://github.com/bblimke/webmock

require 'webmock/rspec'

# The ActiveRecord extensions need testing in the context of a database. I
# did consider NullDB - https://github.com/nulldb/nulldb - but this was too
# far from 'the real thing' for my liking. Instead, we use SQLite in memory
# and DatabaseCleaner to reset state between tests.
#
# http://stackoverflow.com/questions/7586813/fake-an-active-record-model-without-db

require 'database_cleaner'
require 'active_record'
require 'logger'

# Include Alchemy Flux for testing only.

begin
  require 'alchemy-flux'
rescue LoadError
  raise 'Cannot load alchemy-flux; did you run me with "bundle exec..." ?'
end

# Now it's safe to require Rack test code and Hoodoo itself.

require 'rack/test'
require 'hoodoo'

RSpec.configure do | config |

  # Provides familiar-ish 'get'/'post' etc. DSL for simulated URL fetch tests.

  config.include Rack::Test::Methods

  # http://stackoverflow.com/questions/1819614/how-do-i-globally-configure-rspec-to-keep-the-color-and-format-specdoc-o
  #
  # Use color in STDOUT,
  # use color not only in STDOUT but also in pagers and files.

  config.color = true
  config.tty   = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234

  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.

  Kernel.srand config.seed

  # Wake up Database Cleaner.

  DATABASE_CLEANER_STRATEGY = :transaction # MUST NOT be changed
  DatabaseCleaner.strategy = DATABASE_CLEANER_STRATEGY

  database_name = 'hoodoo_test'

  config.before( :suite ) do

    WebMock.disable!

    # Redirect $stderr before each test so a test log gets written without
    # disturbing the RSpec terminal output; make sure the session system is
    # in "test mode"; make sure we get a unique DRb daemon instance for the
    # tests, which we can shut down afterwards.

    base_path = File.join( File.dirname( __FILE__ ), '..', 'log' )
    log       = File.new( File.join( base_path, 'test.log' ), 'a+' )

    $stderr.reopen(log)

    $stderr << "\n" << "*"*80 << "\n"
    $stderr << Time.now.to_s << "\n"
    $stderr << "*"*80 << "\n\n"

    Hoodoo::Services::Middleware.set_log_folder( base_path )

    ENV[ 'HOODOO_DISCOVERY_BY_DRB_PORT_OVERRIDE' ] = Hoodoo::Utilities.spare_port().to_s()

    # Connect to PostgreSQL before tests start.

    spec_helper_connect_to_postgres()

    # Sometimes if a user force quits the spec suite, the hoodoo_test database
    # will not be deleted. The following makes sure it is removed now.

    database_exists = ActiveRecord::Base.connection.execute(
      "SELECT COUNT(*) FROM pg_database WHERE datname = '#{ database_name }'"
    ).any?

    if database_exists
      ActiveRecord::Base.connection.drop_database( database_name )
    end

    # Create the test database (hiding output) and connect to it.

    ActiveRecord::Base.logger = Logger.new( nil )
    ActiveRecord::Base.connection.create_database( database_name )
    ActiveRecord::Base.logger = Logger.new( STDERR )

    spec_helper_connect_to_postgres( database_name )

  end

  config.after( :suite ) do

    # Delete the test database afterwards. Must disconnect from it
    # first, going back to the default 'postgresql' database instead.

    begin
      spec_helper_connect_to_postgres()
      ActiveRecord::Base.connection.drop_database( database_name )
    rescue
      # Ignore exceptions. Any failures to delete the database will
      # be picked up by the at-test-startup precautionary delete
      # anyway.
    end

    # Shut down the DRb discoverer.

    begin
      drb_uri = Hoodoo::Services::Discovery::ByDRb::DRbServer.uri()
      drb_service = DRbObject.new_with_uri( drb_uri )
      drb_service.stop()
    rescue
      # Ignore exceptions. For test subsets or depending on test order,
      # there might not be a DRb service to shut down.
    end

  end

  # Make sure DatabaseCleaner runs between each test.

  config.before( :each ) do
    DatabaseCleaner.start
  end

  config.after( :each ) do
    DatabaseCleaner.clean
  end
end

# Ensure known monkey patches are disabled; tests for the patches
# will enable them for the duration of the test only.
#
[ Hoodoo::Monkey::Patch, Hoodoo::Monkey::Chaos ].each do | monkey |
  monkey.constants.each do | extension_module_name |
    extension_module = monkey.const_get( extension_module_name )

     # Ignore "not registered" exceptions for not-yet-registered patches.
     #
    Hoodoo::Monkey.disable( extension_module: extension_module ) rescue nil
  end
end

# Load all global shared examples.
#
Dir[ "#{ File.dirname( __FILE__ ) }/shared_examples/**/*.rb" ].sort.each { | f | require f }

# Connect to PostgreSQL for test purposes. Generally only used within
# the "spec_helper.rb" file for environment setup and teardown.
#
# +database_name+:: Name of database to which a connection should be
#                   established. If omitted, connects to engine default
#                   of 'postgres'.
#
def spec_helper_connect_to_postgres( database_name = 'postgres' )
  ActiveRecord::Base.establish_connection(
    :adapter  => 'postgresql',
    :username => ENV[ 'DATABASE_USER' ] || 'postgres',
    :password => 'password',
    :host     => '127.0.0.1',
    :port     => ENV[ 'DATABASE_PORT' ] || 5432,
    :database => database_name
  )
end

# For things like ActiveRecord::Migrations used during database-orientated
# tests, or for certain logger tests, have to silence +STDOUT+ chatter to
# avoid messing up RSpec's output, but we need to be sure it's restored.
#
# &block:: Block of code to call while +STDOUT+ is disabled.
#
def spec_helper_silence_stdout( &block )
  spec_helper_silence_stream( $stdout, &block )
end

# Back-end to #spec_helper_silence_stdout; can silence arbitrary streams.
#
# +stream+:: The output stream to silence, e.g. <tt>$stdout</tt>
# &block::   Block of code to call while output stream is disabled.
#
def spec_helper_silence_stream( stream, &block )
  begin
    old_stream = stream.dup
    stream.reopen( File::NULL )
    stream.sync = true

    yield

  ensure
    stream.reopen( old_stream )
    old_stream.close

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
# +app_class+:: Hoodoo::Services::Service subclass for the service to start.
#
# +use_ssl+::   If +true+, SSL self-signed certificates in +spec/files+ are
#               used to support SSL testing, provided certificate chain
#               verification is bypassed. Optional; default is +false+, which
#               uses normal HTTP.
#
def spec_helper_start_svc_app_in_thread_for( app_class, use_ssl = false, app_options = {} )

  port = Hoodoo::Utilities.spare_port()

  Thread.start do
    app = Rack::Builder.new do
      use Hoodoo::Services::Middleware unless app_options[:skip_hoodoo_middleware]
      run app_class.new
    end

    options = {
      :app    => app,
      :Port   => port,
      :Host   => '127.0.0.1',
      :server => :webrick
    }

    if ( use_ssl )
      pem = File.join( File.dirname( __FILE__ ), 'files', 'ssl.pem' )
      key = File.join( File.dirname( __FILE__ ), 'files', 'ssl.key' )

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

# Stub out Memcached with a TransientStore mock client instead. Call via
# a "before :each" block.
#
def spec_helper_use_mock_memcached
  Hoodoo::TransientStore::Mocks::DalliClient.reset()

  allow( Dalli::Client ).to(
    receive( :new ).
    and_return( Hoodoo::TransientStore::Mocks::DalliClient.new )
  )
end

# Stub out Redis with a TransientStore mock client instead. Call via
# a "before :each" block.
#
def spec_helper_use_mock_redis
  Hoodoo::TransientStore::Mocks::Redis.reset()

  allow( Redis ).to(
    receive( :new ).
    and_return( Hoodoo::TransientStore::Mocks::Redis.new )
  )
end

# Add support to count the database queries run within a
# given block. Returns the number of queries run.
#
def spec_helper_count_database_calls_in( &block )
  count = 0
  cb    = ->( name, start_time, finish_time, id, query ) {

    # Only bump the count if the database call is not to CACHE or SCHEMA
    #
    count += 1 unless [ 'CACHE', 'SCHEMA' ].include?( query[ :name ] )
  }

  ActiveSupport::Notifications.subscribed( cb, 'sql.active_record', &block )
  return count
end

# Change a named environment varible's value and call a given block.
# Afterwards, restore the old value of that variable.

def spec_helper_change_environment( name, value, &block )
  old_value = ENV[ name ]
  begin
    ENV[ name ] = value
    yield
  ensure
    ENV[ name ] = old_value
  end
end

# In Ruby 2.5.0 the Ruby team removed <tt>Dir::Tmpname.make_tmpname</tt>:
#
# https://github.com/ruby/ruby/commit/25d56ea7b7b52dc81af30c92a9a0e2d2dab6ff27
#
# Instead we must make our best attempt in plain Ruby ourselves, e.g.:
#
# https://github.com/rails/rails/issues/31458
# https://github.com/rails/rails/pull/31462/files
#
# Since the above solution uses the process number via "$$" it should be safe
# for just this test suite, so we use the same approach here. This method
# returns the full file path for the temporary file, not just a leafname.
#
def spec_helper_tmpfile_path
  time = Time.now.strftime( "%Y%m%d" )
  name = "hoodoo-tests-#{ time }-#{ $$ }-#{ rand( 0x100000000 ).to_s( 36 ) }-fd"

  File.join( Dir::Tmpname.tmpdir, name )
end
