########################################################################
# File::    redis.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Hoodoo::TransientStore plugin supporting Redis.
# ----------------------------------------------------------------------
#           01-Feb-2017 (ADH): Created.
########################################################################

require 'json'
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
      # All given keys are internally prefixed with a namespace of
      # +nz_co_loyalty_hoodoo_transient_store_+ to avoid collision of data
      # stored with this object and other data that may be in the Redis
      # instance identified by +storage_host_uri+.
      #
      def initialize( storage_host_uri: )
        @storage_host_uri = storage_host_uri
        @client           = self.connect_to_redis( storage_host_uri )
      end

      # See Hoodoo::TransientStore::Base#set for details.
      #
      # The payload is encoded into JSON for storage and automatically decoded
      # by #get; so callers don't need to do marshalling to Strings themselves.
      #
      def set( key:, payload:, maximum_lifespan: )
        nk = self.namespaced_key( key )

        @client[ nk ] = JSON.fast_generate( payload )
        @client.expire( nk, maximum_lifespan )
      end

      # See Hoodoo::TransientStore::Base#get for details.
      #
      def get( key: )
        JSON.parse( @client[ self.namespaced_key( key ) ] )
      end

      # See Hoodoo::TransientStore::Base#delete for details.
      #
      def delete( key: )
        @client.del( self.namespaced_key( key ) )
      end

    private

      # Given a simple key to Redis data (expressed as a String), return a
      # namespaced version by adding a 'nz_co_loyalty_hoodoo_transient_store_'
      # prefix.
      #
      def namespaced_key( key )
        'nz_co_loyalty_hoodoo_transient_store_' + key
      end

      # Connect to Redis if possible and return the connected Redis client
      # instance, else raise an exception.
      #
      # +host+:: Connection URI, e.g. <tt>localhost:11211</tt>.
      #
      def connect_to_redis( host )
        exception = nil
        stats     = nil
        client    = nil

        begin
          client = ::Redis.new(
            :url => host
              :namespace  => :nz_co_loyalty_hoodoo_transient_store_
          )

          stats = client.stats()

        rescue => e
          exception = e

        end

        if stats.nil?
          if exception.nil?
            raise "Hoodoo::TransientStore::Memcached: Did not get back meaningful data from Memcached at '#{ host }'"
          else
            raise "Hoodoo::TransientStore::Memcached: Cannot connect to Memcached at '#{ host }': #{ exception.to_s }"
          end
        else
          return client
        end
      end

    end

    Hoodoo::TransientStore.register(
      as:    :redis,
      using: Hoodoo::TransientStore::Redis
    )

  end
end
