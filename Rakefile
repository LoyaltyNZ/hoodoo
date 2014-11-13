require 'rake'
require 'rspec/core/rake_task'
require 'rdoc/task'

RSpec::Core::RakeTask.new( :default ) do | t |
end

Rake::RDocTask.new do | rd |
 rd.rdoc_files.include( 'README.md', 'lib/**/*.rb' )
 rd.rdoc_dir = 'docs/rdoc'
 rd.title = 'ApiTools'
 rd.main = 'README.md'
end
