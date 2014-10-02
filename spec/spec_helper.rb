# Configure the code coverage analyser.

require 'simplecov'
require 'simplecov-rcov'

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter '_spec'
end

# The normal logger logs to stdout and stderr - stderr output can be useful
# in real tests but pollutes visual test output. Redirect it. "#error" calls
# to the ApiTools logger will end up in the log.

log = File.new( 'test.log', 'a+')
$stderr.reopen(log)

$stderr << "\n" << "*"*80 << "\n"
$stderr << Time.now.to_s << "\n"
$stderr << "*"*80 << "\n\n"

# Provides familiar-ish 'get'/'post' etc. DSL for simulated URL fetch tests.

require 'rack/test'

RSpec.configure do | config |
  config.include Rack::Test::Methods
end

require 'api_tools'
