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

  s.required_ruby_version = '>= 2.3.5'

  s.add_runtime_dependency     'dalli',            '~>  2.7' # Memcached client
  s.add_runtime_dependency     'rack'

  s.add_development_dependency 'activerecord',     '~>  5.2.4.3'
  s.add_development_dependency 'activesupport',    '~>  5.2.4.3'
  s.add_development_dependency 'airbrake',         '~>  7.3'  # airbrake.io
  s.add_development_dependency 'airbrake-ruby',    '~>  2.11' # airbrake.io
  s.add_development_dependency 'alchemy-flux',     '= 1.2.1' # Since 1.3+ drop Ruby 2.2 support
  s.add_development_dependency 'bundle-audit'
  s.add_development_dependency 'byebug',           '~> 10.0'
  s.add_development_dependency 'database_cleaner', '~>  1.7'
  s.add_development_dependency 'le',               '~>  2.7'  # logentries.com
  s.add_development_dependency 'pg',               '~>  1.0'
  s.add_development_dependency 'rack-test',        '~>  1.1'
  s.add_development_dependency 'rake',             '~> 12.0'
  s.add_development_dependency 'raygun4ruby',      '~>  2.7'  # raygun.io
  s.add_development_dependency 'redis',            '~>  4.0' # Redis client
  s.add_development_dependency 'rspec',            '~>  3.8'
  s.add_development_dependency 'rspec-mocks',      '~>  3.8'
  s.add_development_dependency 'simplecov-rcov',   '~>  0.2'
  s.add_development_dependency 'timecop',          '~>  0.9'
  s.add_development_dependency 'webmock',          '~>  3.4'
end
