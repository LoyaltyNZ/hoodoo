# Configure the code coverage analyser.

require 'simplecov'
require 'simplecov-rcov'

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter '_spec'
end

require 'rack/test'

RSpec.configure do | config |

  # Provides familiar-ish 'get'/'post' etc. DSL for simulated URL fetch tests.

  config.include Rack::Test::Methods

  # The normal logger logs to stdout and stderr - stderr output can be useful
  # in real tests but pollutes visual test output. Redirect it. "#error" calls
  # to the ApiTools logger will end up in the log.

  config.before( :all ) do
    log = File.new( 'test.log', 'a+')
    $stderr.reopen(log)

    $stderr << "\n" << "*"*80 << "\n"
    $stderr << Time.now.to_s << "\n"
    $stderr << "*"*80 << "\n\n"
  end
end

require 'api_tools'
