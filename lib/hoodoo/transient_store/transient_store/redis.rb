########################################################################
# File::    redis.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Hoodoo::TransientStore plugin supporting Redis.
# ----------------------------------------------------------------------
#           01-Feb-2017 (ADH): Created.
########################################################################

begin
  require 'json'
  require 'redis'
rescue LoadError
end

module Hoodoo
  class TransientStore

    # Hoodoo::TransientStore plugin supporting {Redis}[https://redis.io]. The
    # {redis-rb gem}[https://github.com/redis/redis-rb] is used for server
    # communication.
    #
    class Redis < Hoodoo::TransientStore::Base

      # See Hoodoo::TransientStore::Base::new for details.
      #
      # Do not instantiate this class directly. Use
      # Hoodoo::TransientStore::new.
      #
      # The {redis-rb gem}[https://github.com/redis/redis-rb] is used to talk
      # to {Redis}[https://redis.io] and requires connection UIRs with a
      # +redis+ protocol, such as <tt>redis://localhost:6379</tt>.
      #
      # TCP keep-alive is enabled for the server connection.
      #
      # All given keys are internally prefixed with a namespace of
      # +nz_co_loyalty_hoodoo_transient_store_+ to avoid collision of data
      # stored with this object and other data that may be in the Redis
      # instance identified by +storage_host_uri+.
      #
      def initialize( storage_host_uri: )
        super # Pass all arguments through -> *not* 'super()'
        @client = connect_to_redis( storage_host_uri )
      end

      # See Hoodoo::TransientStore::Base#set for details.
      #
      # The payload is encoded into JSON for storage and automatically decoded
      # by #get; so callers don't need to do marshalling to Strings themselves.
      #
      def set( key:, payload:, maximum_lifespan: )
        nk = namespaced_key( key )

        @client[ nk ] = JSON.fast_generate( payload )
        @client.expire( nk, maximum_lifespan )

        true
      end

      # See Hoodoo::TransientStore::Base#get for details.
      #
      def get( key: )
        result = @client[ namespaced_key( key ) ]
        return result.nil? ? nil : ( JSON.parse( result ) rescue nil )
      end

      # See Hoodoo::TransientStore::Base#delete for details.
      #
      def delete( key: )
        @client.del( namespaced_key( key ) )
        true
      end

      # See Hoodoo::TransientStore::Base#close for details.
      #
      def close
        @client.quit()
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
        info      = nil
        client    = nil

        begin
          client = ::Redis.new(
            :url           => host,
            :tcp_keepalive => 1
          )

          info = client.info( 'CPU' )

        rescue => e
          exception = e

        end

        if info.nil?
          if exception.nil?
            raise "Hoodoo::TransientStore::Redis: Did not get back meaningful data from Redis at '#{ host }'"
          else
            raise "Hoodoo::TransientStore::Redis: Cannot connect to Redis at '#{ host }': #{ exception.to_s }"
          end
        else
          return client
        end
      end

    end

    Hoodoo::TransientStore.register(
      as:    :redis,
      using: Hoodoo::TransientStore::Redis
    ) if defined?( ::Redis )

  end
end
