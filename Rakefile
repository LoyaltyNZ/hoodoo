require 'rake'
require 'rspec/core/rake_task'
require 'rdoc/task'

RSpec::Core::RakeTask.new( :default ) do | t |
end

Rake::RDocTask.new do | rd |
 rd.rdoc_files.include( 'README.md', 'lib/**/*.rb' )
 rd.rdoc_dir = 'docs/rdoc'
 rd.title = 'Hoodoo'
 rd.main = 'README.md'
end

desc 'Check if latest version in CHANGELOG.md matches with current version number'
task :check_version do
 changelog = File.join(File.dirname(__FILE__), 'CHANGELOG.md')
 raise "missing CHANGELOG.md" unless File.exists?(changelog)

 if File.read(changelog).match(/[0-9]+\.[0-9]+\.[0-9]+/)[0] != Hoodoo::VERSION
  raise "Latest version in CHANGELOG.md does not match Hoodoo::VERSION"
 end
end
