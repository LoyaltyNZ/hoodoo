$:.push File.expand_path('../lib', __FILE__)
require 'api_tools/version'

Gem::Specification.new do |s|
  s.name        = 'api_tools'
  s.version     = ApiTools::VERSION
  s.date        = '2014-12-02'
  s.summary     = 'Opinionated APIs'
  s.description = 'Simplify the implementation of consistent services within an API-based software platform.'
  s.authors     = ["Tom Cully", "Andrew Hodgkinson"]
  s.email       = ['tom.cully@loyalty.co.nz', 'andrew.hodgkinson@loyalty.co.nz']
  s.license     = 'MIT'

  s.files       = Dir.glob('lib/**/*.rb')
  s.bindir      = 'bin'
  s.executables = ['api_tools']
  s.test_files  = Dir.glob('spec/**/*.rb')
  s.homepage    = 'http://github.com/LoyaltyNZ/api_tools'

  s.required_ruby_version = '>= 2.1.2'

  s.add_runtime_dependency     'json_builder',     '~> 3.1'
  s.add_runtime_dependency     'uuidtools',        '~> 2.1'
  s.add_runtime_dependency     'dalli',            '~> 2.7'

  s.add_development_dependency 'rake',             '~> 10.4'
  s.add_development_dependency 'simplecov-rcov',   '~> 0.2'
  s.add_development_dependency 'rdoc',             '~> 4.1'
  s.add_development_dependency 'sdoc',             '~> 0.4'
  s.add_development_dependency 'rack-test',        '~> 0.6'
  s.add_development_dependency 'rspec',            '~> 3.1'
  s.add_development_dependency 'rspec-mocks',      '~> 3.1'
  s.add_development_dependency 'activerecord',     '~> 4.1'
  s.add_development_dependency 'database_cleaner', '~> 1.3'
  s.add_development_dependency 'sqlite3',          '~> 1.3'
  s.add_development_dependency 'raygun4ruby',      '~> 1.1' # raygun.io
  s.add_development_dependency 'airbrake',         '~> 4.1' # airbrake.io
  s.add_development_dependency 'le',               '~> 2.6' # logentries.com
end
