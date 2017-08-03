########################################################################
# File::    transient_store.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Include temporary/transient storage abstraction layers.
# ----------------------------------------------------------------------
#           01-Feb-2017 (ADH): Created
########################################################################

# Core abstraction

require 'hoodoo/transient_store/transient_store'
require 'hoodoo/transient_store/transient_store/base'

# Storage engine plugins

require 'hoodoo/transient_store/transient_store/memcached'
require 'hoodoo/transient_store/transient_store/redis'
require 'hoodoo/transient_store/transient_store/memcached_redis_mirror'

# Mock plugin back-ends for test or other stubbing purposes.

require 'hoodoo/transient_store/mocks/dalli_client'
require 'hoodoo/transient_store/mocks/redis'
