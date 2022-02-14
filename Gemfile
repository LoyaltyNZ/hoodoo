source "https://rubygems.org"

# rdoc 6.2 has CVE-2021-31799, and rdoc 6.3 requires ruby >= 2.4
# URL: https://www.ruby-lang.org/en/news/2021/05/02/os-command-injection-in-rdoc/
#
# disable rdoc & sdoc for now until we can migrate every apps past 2.3.5 (especially FlyBuys)
#
# gem 'sdoc', :git => 'https://github.com/pond/sdoc.git', :branch => 'master'

# if rdoc files re-generation is required, this sdoc version can be used
#
# 1) uncomment
# 2) bundle (to install the gems)
# 3) bundle exec rake rerdoc (see README#Documentation (RDoc))
# 4) comment out gem
# 5) bundle (to exclude gems at step 2 from Gemfile.lock)
#
# gem 'sdoc', :git => 'https://github.com/pond/sdoc.git', :ref => 'e1e35566f9f207bffb3511fea4779629de94d029'

gemspec
