Gem::Specification.new do |s|
  s.name        = 'api_tools'
  s.version     = '0.0.1'
  s.date        = '2014-02-10'
  s.summary     = "A gem for simplifying the implementation of Loyalty Platform services."
  s.description = "A gem for simplifying the implementation of Loyalty Platform services."
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
  s.add_development_dependency "rack-test"
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-mocks"
  s.add_runtime_dependency 'json_builder'
  s.add_runtime_dependency 'uuidtools'
  s.add_runtime_dependency 'dalli'
  s.add_runtime_dependency 'bunny'
  s.add_runtime_dependency 'msgpack'
  s.add_runtime_dependency 'rest-client'
end
