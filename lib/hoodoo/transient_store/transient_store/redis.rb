########################################################################
# File::    redis.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Hoodoo::TransientStore plugin supporting Redis.
# ----------------------------------------------------------------------
#           01-Feb-2017 (ADH): Created.
########################################################################

require 'redis'

module Hoodoo
  class TransientStore

    # Hoodoo::TransientStore plugin supporting {Redis}[https://redis.io]. The
    # {redis-rb gem}[https://github.com/redis/redis-rb] is used for server
    # communication.
    #
    class Redis < Hoodoo::TransientStore::Base

      # See Hoodoo::TransientStore::Base::new for details.
      #
      # The {redis-rb gem}[https://github.com/redis/redis-rb] is used to talk
      # to {Redis}[https://redis.io] and requires connection UIRs with a
      # +redis+ protocol, such as <tt>redis://localhost:6379</tt>.
      #
      def initialize( storage_host_uri: )
      end

      # See Hoodoo::TransientStore::Base#set for details.
      #
      def set( key:, payload:, maximum_lifespan: nil )
      end

      # See Hoodoo::TransientStore::Base#get for details.
      #
      def get( key: )
      end

      # See Hoodoo::TransientStore::Base#delete for details.
      #
      def delete( key: )
      end

    end

    Hoodoo::TransientStore.register(
      as:    :redis,
      using: Hoodoo::TransientStore::Redis
    )
  end
end
