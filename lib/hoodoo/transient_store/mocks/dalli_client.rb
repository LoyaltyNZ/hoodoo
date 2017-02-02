########################################################################
# File::    dalli_client.rb
# (C)::     Loyalty New Zealand 2017
#
# Purpose:: A mock/fake Dalli::Client minimal implementation as an
#           alternative test back-end for Memcached-independent tests.
# ----------------------------------------------------------------------
#           02-Feb-2017 (ADH): Created.
########################################################################

module Hoodoo
  class TransientStore

    # Mock back-end code used by tests to allow them to run without a
    # dependency on the real engine (though the real engine is always
    # recommended and Hoodoo core tests always cover both).
    #
    class Mocks

      # Mock known uses of Dalli::Client with test implementations.
      # Use explicitly, or as an RSpec implicit mock via something like
      # this:
      #
      #     allow( Dalli::Client ).to(
      #       receive( :new ).
      #       and_return( Hoodoo::TransientStore::Mocks::DalliClient.new )
      #     )
      #
      # ...whenever you need to stub out real Memcached. You will
      # probably want to add:
      #
      #     before :all do # (or ":each")
      #       Hoodoo::TransientStore::Mocks::DalliClient.reset()
      #     end
      #
      # ...to "clean out Memcached" before or between tests. You can
      # check the contents of mock Memcached by examining ::store's
      # hash of data.
      #
      # The test coverage for Hoodoo::TransientStore selects this backend in
      # passing. Generally speaking you should favour Hoodoo::TransientStore
      # over hard-coding to a storage engine available by the Hoodoo
      # abstraction and, as a result, may never need this mock class at all.
      #
      class DalliClient
        @@store = {}

        # For test analysis, return the hash of 'memcached' mock data.
        #
        # Entries are referenced by the key you used to originally
        # store them; values are hashes with ":expires_at" giving an
        # expiry time or "nil" and ":value" giving your stored value.
        #
        def self.store
          @@store
        end

        # Wipe out all saved data.
        #
        def self.reset
          @@store = {}
        end

        # Pass +true+ to bypass the mock client (subject to the caller
        # reading ::bypass?) to e.g. get test code coverage on real
        # Memcached. Pass +false+ otherwise.
        #
        # (Deprecated, but indefinitely maintained).
        #
        def self.bypass( bypass_boolean )
          @@bypass = bypass_boolean
        end

        @@bypass = false

        # If +true+, bypass this class and use real Dalli::Client; else
        # don't. Default return value is +false+.
        #
        # (Deprecated, but indefinitely maintained).
        #
        def self.bypass?
          @@bypass
        end

        # Get the data stored under the given key. Returns +nil+ if
        # not found / expired.
        #
        # +key+:: Key to look up (see #set).
        #
        def get( key )
          data = @@store[ key ]
          return nil if data.nil?

          expires_at = data[ :expires_at ]
          return nil unless expires_at.nil? || Time.now < expires_at

          return data[ :value ]
        end

        # Set data for a given key.
        #
        # +key+::   Key under which to store data.
        #
        # +value+:: Data to store.
        #
        # +ttl+::   (Optional) time-to-live ('live' as in living, not as in
        #           'live TV') - a value in seconds, after which the data is
        #           considered expired. If omitted, the data does not expire.
        #
        def set( key, value, ttl = nil )
          data = {
            :expires_at => ttl.nil? ? nil : Time.now.utc + ttl,
            :value      => value
          }

          @@store[ key ] = data
          true
        end

        # Remove data for the given key.
        #
        def delete( key )
          if @@store.has_key?( key )
            @@store.delete( key )
            true
          else
            false
          end
        end

        # Mock 'stats' health check.
        #
        def stats

          # Should really be a Hash, but kept as 'true' in case any existing
          # client depends on this; it isn't too important either way.
          #
          true

        end
      end
    end
  end
end
