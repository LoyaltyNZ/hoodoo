$:.push File.expand_path( '../lib', __FILE__ )
require 'hoodoo/version'

Gem::Specification.new do | s |
  s.name        = 'hoodoo'
  s.version     = Hoodoo::VERSION
  s.date        = '2016-02-23'
  s.summary     = 'Opinionated APIs'
  s.description = 'Simplify the implementation of consistent services within an API-based software platform.'
  s.authors     = [ 'Loyalty New Zealand' ]
  s.email       = [ 'andrew.hodgkinson@loyalty.co.nz' ]
  s.license     = 'LGPL-3.0'

  s.files       = Dir.glob( 'lib/**/*.rb' )
  s.bindir      = 'bin'
  s.executables = [ 'hoodoo' ]
  s.test_files  = Dir.glob( 'spec/**/*.rb' )
  s.homepage    = 'https://loyaltynz.github.io/hoodoo/'

  s.required_ruby_version = '>= 2.1'

  s.add_runtime_dependency     'kgio',             '~> 2.9' # Speeds up Dalli
  s.add_runtime_dependency     'dalli',            '~> 2.7' # Memcached client

  s.add_development_dependency 'rake',             '~> 10.4'
  s.add_development_dependency 'simplecov-rcov',   '~> 0.2'
  s.add_development_dependency 'rdoc',             '~> 4.2' # See also 'sdoc' in Gemfile
  s.add_development_dependency 'rack-test',        '~> 0.6'
  s.add_development_dependency 'alchemy-flux',     '~> 0.1'
  s.add_development_dependency 'rspec',            '~> 3.3'
  s.add_development_dependency 'rspec-mocks',      '~> 3.3'
  s.add_development_dependency 'activerecord',     '~> 4.2'
  s.add_development_dependency 'activesupport',    '~> 4.2'
  s.add_development_dependency 'database_cleaner', '~> 1.4.0' # 1.5.x breaks tests
  s.add_development_dependency 'pg',               '~> 0.18'
  s.add_development_dependency 'byebug',           '~> 3.5'
  s.add_development_dependency 'timecop',          '~> 0.8'
  s.add_development_dependency 'raygun4ruby',      '~> 1.1' # raygun.io
  s.add_development_dependency 'airbrake',         '~> 4.3' # airbrake.io
  s.add_development_dependency 'le',               '~> 2.6' # logentries.com
end
