$:.push File.expand_path('../lib', __FILE__)
require 'api_tools/version'

Gem::Specification.new do |s|
  s.name        = 'api_tools'
  s.version     = ApiTools::VERSION
  s.date        = '2014-11-12'
  s.summary     = 'Simplify the implementation of services within an API-based software platform.'
  s.description = 'Simplify the implementation of services within an API-based software platform.'
  s.authors     = ["Tom Cully", "Andrew Hodgkinson"]
  s.email       = ['tom.cully@loyalty.co.nz', 'andrew.hodgkinson@loyalty.co.nz']
  s.files       = Dir.glob('lib/**/*.rb')
  s.bindir      = 'bin'
  s.executables = ['api_tools']
  s.test_files  = Dir.glob('spec/**/*.rb')
  s.homepage    = 'http://github.com/LoyaltyNZ/api_tools'

  s.required_ruby_version = '>= 2.1.2'

  s.add_development_dependency "rake"
  s.add_development_dependency "simplecov-rcov"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "sdoc"
  s.add_development_dependency "rack-test"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-mocks"
  s.add_development_dependency "activerecord"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "sqlite3"

  s.add_runtime_dependency 'json_builder'
  s.add_runtime_dependency 'uuidtools'
  s.add_runtime_dependency 'dalli'
end
