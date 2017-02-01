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

    # Hoodoo::TransientStore plugin supporting Memcached. The Dalli gem is
    # used for Memcached communication.
    #
    # * https://github.com/petergoldstein/dalli
    #
    class Memcached < Hoodoo::TransientStore::Base

      # See Hoodoo::TransientStore::Base#initialize for details.
      #
      # The Dalli gem is used to talk to Memcached and accepts connection UIRs
      # of simple, terse forms such as <tt>'localhost:11211'</tt>.
      #
      def initialize( storage_host_uri: )
        @storage_host_uri = storage_host_uri
        @client           = self.connect_to_memcached( storage_host_uri )
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
              :namespace  => :nz_co_loyalty_hoodoo_session_
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
