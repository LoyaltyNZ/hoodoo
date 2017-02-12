source "https://rubygems.org"

# SDoc currently works better with patches from a specific repository's
# fork, but the :git option is not available inside a gemspec file.

gem 'sdoc', :git => 'https://github.com/pond/sdoc.git', :branch => 'master'

group :development, :test do
  gem 'rack',         '~> 2.0'
  gem 'alchemy-flux', '1.1'
end

# Get other non-test dependencies via the gemspec.

gemspec
