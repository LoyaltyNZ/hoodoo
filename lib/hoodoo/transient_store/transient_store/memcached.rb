########################################################################
# File::    redis.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: Hoodoo::TransientStore plugin supporting Memcached.
# ----------------------------------------------------------------------
#           01-Feb-2017 (ADH): Created.
########################################################################

require 'dalli'

module Hoodoo
  class TransientStore

    # Hoodoo::TransientStore plugin for {Memcached}[https://memcached.org]. The
    # {Dalli gem}[https://github.com/petergoldstein/dalli] is used for server
    # communication.
    #
    class Memcached < Hoodoo::TransientStore::Base

      # See Hoodoo::TransientStore::Base::new for details.
      #
      # The {Dalli gem}[https://github.com/petergoldstein/dalli] is used to
      # talk to {Memcached}[https://memcached.org] and accepts connection UIRs
      # of simple, terse forms such as <tt>'localhost:11211'</tt>. Connections
      # are configured with JSON serialisation, compression off and a forced
      # namespace of +nz_co_loyalty_hoodoo_transient_store_+ to avoid collision
      # of data stored with this object and other data that may be in the
      # Memcached instance identifier by +storage_host_uri+.
      #
      def initialize( storage_host_uri: )
        @storage_host_uri = storage_host_uri
        @client           = self.connect_to_memcached( storage_host_uri )
      end

      # See Hoodoo::TransientStore::Base#set for details.
      #
      def set( key:, payload:, maximum_lifespan: nil )
        @client.set( key, payload, maximum_lifespan )
      end

      # See Hoodoo::TransientStore::Base#get for details.
      #
      def get( key: )
        @client.get( key )
      end

      # See Hoodoo::TransientStore::Base#delete for details.
      #
      def delete( key: )
        @client.delete( key )
      end

    private

      # Connect to Memcached if possible and return the connected Dalli client
      # instance, else raise an exception.
      #
      # +host+:: Connection URI, e.g. <tt>localhost:11211</tt>.
      #
      def connect_to_memcached( host )
        exception = nil
        stats     = nil
        mclient   = nil

        begin
          client = ::Dalli::Client.new(
            host,
            {
              :compress   => false,
              :serializer => JSON,
              :namespace  => :nz_co_loyalty_hoodoo_transient_store_
            }
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
      as:    :memcached,
      using: Hoodoo::TransientStore::Memcached
    )
  end
end
