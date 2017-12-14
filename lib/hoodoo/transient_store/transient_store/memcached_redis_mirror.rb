########################################################################
# File::    memcached_redis_mirror.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Hoodoo::TransientStore plugin supporting storage into both
#           Memcached and Redis simultaneously.
# ----------------------------------------------------------------------
#           01-Feb-2017 (ADH): Created.
########################################################################

module Hoodoo
  class TransientStore

    # Hoodoo::TransientStore plugin supporting storage into both
    # {Memcached}[https://memcached.org] and {Redis}[https://redis.io]
    # simultaneously.
    #
    # The implementation uses Hoodoo::TransientStore::Memcached and
    # Hoodoo::TransientStore::Redis to talk to the two storage engines.
    #
    # When looking up data with #get, the requested item must be found in both
    # storage engines. If it is found in only one, the other one is deleted to
    # keep maximum pool space available in both and +nil+ will be returned for
    # the lookup.
    #
    # Note unusual requirements for the connection URI data provided to the
    # #initialize call.
    #
    # The mirroring storage engine plug-in is useful if migrating from one of
    # these engines to another without invalidating data present in the one
    # from which you are migrating away. Change to using the mirrored storage
    # engine for as long as the maximum item expiry period in the old engine,
    # then once you know all old engine items must have been expired, cut over
    # to just the new engine.
    #
    class MemcachedRedisMirror < Hoodoo::TransientStore::Base

      # Command an instance to allow #get to return values which are only found
      # in one or the other storage engine, or in both.
      #
      # Permitted values are:
      #
      # +:memcached+:: Only Memcached needs to have a value for a key
      # +:redis+::     Only Redis needs to have a value for a key
      # +both+::       Both engines must have the key
      #
      # This is useful in migration scenarios where moving from Memcached to
      # Redis or vice versa. If wishing to be able to still read old data only
      # in Memcached, set +:memcached+; else +:redis+. That way, data only in
      # the old engine but not yet in the new is still considered valid and
      # read back. For true mirroring which requires both stores to have the
      # value, use +:both+.
      #
      # The default is +:both+.
      #
      attr_accessor :get_keys_from

      # See Hoodoo::TransientStore::Base::new for details.
      #
      # Do not instantiate this class directly. Use
      # Hoodoo::TransientStore::new.
      #
      # The +storage_host_uri+ parameter is necessarily unusual here. It must
      # be either _a Hash_ with Symbol keys +:memcached+ and +:redis+, or a
      # serialised JSON string representing the same information. These values
      # define the actual storage engine host URI for the respective engines.
      # For example, to connect to locally running engines configured on their
      # default ports, pass this Hash in +storage_host_uri+:
      #
      #   {
      #     :memcached => 'localhost:11211',
      #     :redis     => 'redis://localhost:6379'
      #   }
      #
      #   OR
      #
      #   "{
      #     \"memcached\": \"localhost:11211\",
      #     \"redis\":     \"redis://localhost:6379\"
      #   }"
      #
      # See Hoodoo::TransientStore::Memcached::new and
      # Hoodoo::TransientStore::Redis::new for details of connection URI
      # requirements for those engines.
      #
      # The value of the +namespace+ parameter applies equally to both engines.
      #
      def initialize( storage_host_uri:, namespace: )
        storage_host_uri = deserialize_and_symbolize( storage_host_uri )

        super # Pass all arguments through -> *not* 'super()'

        unless storage_host_uri.is_a?( Hash ) &&
               storage_host_uri.has_key?( :memcached ) &&
               storage_host_uri.has_key?( :redis )
          raise 'Hoodoo::TransientStore::MemcachedRedisMirror: Bad storage host URI data passed to constructor'
        end

        @get_keys_from   = :both
        @memcached_store = Hoodoo::TransientStore::Memcached.new( storage_host_uri: storage_host_uri[ :memcached ], namespace: namespace )
        @redis_store     =     Hoodoo::TransientStore::Redis.new( storage_host_uri: storage_host_uri[ :redis     ], namespace: namespace )
      end

      # See Hoodoo::TransientStore::Base#set for details.
      #
      def set( key:, payload:, maximum_lifespan: )
        memcached_result = @memcached_store.set( key: key, payload: payload, maximum_lifespan: maximum_lifespan )
        redis_result     =     @redis_store.set( key: key, payload: payload, maximum_lifespan: maximum_lifespan )

        return memcached_result && redis_result
      end

      # See Hoodoo::TransientStore::Base#get for details.
      #
      # The requested item must be found in both Memcached and Redis. If it is
      # found in only one, the other one is deleted to keep maximum pool space
      # available in and +nil+ will be returned.
      #
      # If #get_keys_from is configured for +:both+ and the data for some
      # reason has ended up differing in the two stores - most likely because
      # something modified just one of them (perhaps there is outdated code
      # kicking around which is writing to just one) - then the Memcached copy
      # will "win" and the Redis value will be ignored.
      #
      def get( key: )
        case @get_keys_from
          when :both
            memcached_result = @memcached_store.get( key: key )
            redis_result     =     @redis_store.get( key: key )

            if @get_keys_from == :both && ( memcached_result.nil? || redis_result.nil? )
              delete( key: key )
              return nil
            else
              return memcached_result
            end

          when :memcached
            return @memcached_store.get( key: key )

          when :redis
            return @redis_store.get( key: key )

          else
            raise "Hoodoo::TransientStore::Base\#get: Invalid prior value given in \#get_keys_from= of '#{ @get_keys_from.inspect }' - only ':both', ':memcached' or ':redis' are allowed"

        end
      end

      # See Hoodoo::TransientStore::Base#delete for details.
      #
      def delete( key: )
        exception = nil

        begin
          @memcached_store.delete( key: key )
        rescue => e
          exception = e
        end

        # But allow Redis delete to still be attempted...

        begin
          @redis_store.delete( key: key )
        rescue => e
          exception ||= e
        end

        if exception.nil?
          return true
        else
          raise exception
        end
      end

      # See Hoodoo::TransientStore::Base#close for details.
      #
      def close
        @memcached_store.close() rescue nil # Rescue so that Redis "close()" is still attempted.
            @redis_store.close()
      end

      private

      # Helper method for deserialising JSON objects and enforcing hash
      # keys are symbolised.
      #
      def deserialize_and_symbolize( obj )
        obj = JSON.parse( obj ) rescue obj

        Hoodoo::Utilities.symbolize( obj )
      end

    end

    Hoodoo::TransientStore.register(
      as:    :memcached_redis_mirror,
      using: Hoodoo::TransientStore::MemcachedRedisMirror
    ) if ( defined?( ::Redis ) && defined?( ::Dalli ) )

  end
end
