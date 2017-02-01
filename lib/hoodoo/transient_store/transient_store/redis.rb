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

    # Hoodoo::TransientStore plugin supporting Redis.
    #
    class Redis < Hoodoo::TransientStore::Base

      # See Hoodoo::TransientStore::Base#initialize for details.
      #
      # The Redis-RB gem is used to talk to Redis and accepts connection UIRs
      # with a +redis+ protocol, such as <tt>'redis://localhost:6379'</tt>.
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
