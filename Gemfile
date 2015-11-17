source "https://rubygems.org"

gemspec

# Ugly hack for testing; once AlchemyAMQ is public, we won't need the :git
# reference and this can go in the gemspec where it belongs.

group :test do
  gem 'alchemy-amq', :git => 'git@github.com:LoyaltyNZ/alchemy-amq.git', :branch => 'master'
end
