source "https://rubygems.org"

gemspec

# Ugly hack for testing; once AMQEndpoint is public, we won't need the :git
# reference and this can go in the gemspec where it belongs.

group :test do
  gem 'amq-endpoint', :git => 'git@github.com:LoyaltyNZ/amq-endpoint.git', :branch => 'master'
  gem 'byebug'
end
