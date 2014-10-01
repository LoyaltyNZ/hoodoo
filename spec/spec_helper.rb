require 'simplecov'
require 'simplecov-rcov'

SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter '_spec'
end

require 'api_tools'
require 'rack/test'

RSpec.configure do | config |
  config.include Rack::Test::Methods
end
