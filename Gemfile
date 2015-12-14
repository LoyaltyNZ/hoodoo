source "https://rubygems.org"

# SDoc currently works better with patches from a specific repository's
# fork, but the :git option is not available inside a gemspec file.

gem 'sdoc', :git => 'https://github.com/pond/sdoc.git', :branch => 'master'

# Get other non-test dependencies via the gemspec.

gemspec

# TODO: See spec/alchemy/alchemy-amq.rb. Put Alchemy into the gemspec as
#       described below, for real Alchemy once open. Get rid of the other
#       things added below, which are depdencies that Alchemy would pull
#       in itself anyway.
#
# # Ugly hack for testing; once AlchemyAMQ is public, we won't need the :git
# # reference and this can go in the gemspec where it belongs.
#
group :test do
  gem 'msgpack'
  # gem 'alchemy-amq', :git => 'git@github.com:LoyaltyNZ/alchemy-amq.git', :branch => 'master'
end
