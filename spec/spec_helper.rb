require 'simplecov'
require 'simplecov-rcov'
SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
SimpleCov.start do
  add_filter '_spec'
end

require 'rack/test'
require 'api_tools'

RSpec.configure do |c|
end
