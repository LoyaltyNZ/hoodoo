$:.push File.expand_path( '../lib', __FILE__ )
require 'hoodoo/version'

Gem::Specification.new do | s |
  s.name        = 'hoodoo'
  s.version     = Hoodoo::VERSION
  s.date        = Hoodoo::DATE
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

  s.required_ruby_version = '>= 2.2.8'

  s.add_runtime_dependency     'dalli',            '~> 2.7' # Memcached client

  s.add_development_dependency 'redis',            '~> 3.3' # Redis client
  s.add_development_dependency 'rake',             '~> 12.0'
  s.add_development_dependency 'simplecov-rcov',   '~> 0.2'

  s.add_development_dependency 'rdoc',             '~> 5.1' # See also 'sdoc' in Gemfile
  s.add_development_dependency 'rack-test',        '~> 0.6'
  s.add_development_dependency 'rspec',            '~> 3.5'
  s.add_development_dependency 'rspec-mocks',      '~> 3.5'
  s.add_development_dependency 'webmock',          '~> 3.3'
  s.add_development_dependency 'activerecord',     '~> 5.1'
  s.add_development_dependency 'activesupport',    '~> 5.1'
  s.add_development_dependency 'database_cleaner', '~> 1.6'
  s.add_development_dependency 'pg',               '~> 0.21'
  s.add_development_dependency 'byebug',           '~> 9.0'
  s.add_development_dependency 'timecop',          '~> 0.8'
  s.add_development_dependency 'raygun4ruby',      '~> 2.6' # raygun.io
  s.add_development_dependency 'airbrake-ruby',    '~> 2.6' # airbrake.io
  s.add_development_dependency 'airbrake',         '~> 7.1' # airbrake.io
  s.add_development_dependency 'le',               '~> 2.7' # logentries.com
end
