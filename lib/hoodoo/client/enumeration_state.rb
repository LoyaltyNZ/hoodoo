########################################################################
# File::    augmented_array.rb.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: A subclass of Ruby standard library Array used by the
#           Hoodoo::Client::Endpoint family.
# ----------------------------------------------------------------------
#           11-Dec-2014 (ADH): Created.
#           05-Mar-2015 (ADH): Moved to Hoodoo::Client.
########################################################################

module Hoodoo
  class Client # Just used as a namespace here

    module EnumerationState

      attr_reader :query_hash, :endpoint

      def query_hash=( query_hash )
        @query_hash           = query_hash.nil? ? {} : query_hash.dup
        @query_hash[ :limit ] = 50 unless @query_hash.has_key?( :limit )
      end

      def endpoint=( endpoint )
        @endpoint = endpoint
      end

      def enumerate_all

        raise "Must provide a block to enumerate_all" unless block_given?
        raise "Missing query_hash"                    unless @query_hash

        # Assuming the caller has just called 'list', so self contains the
        # first batch of results
        offset = 0
        results = self

        loop do
          if results.size > 0

            # Yield a resource at a time, in the form of an AugmentedHash
            results.each do | result |
              yield copy_hash_errors_and_options( result, results )
            end

            # Resource implementation decides the :batch_size
            batch_size = [1, results.size].max

            offset += batch_size
            @query_hash[:offset] = offset
            results = endpoint.list(@query_hash)

          else

            # Service returns no results, but returns an error, must yield that
            # to the caller, otherwise it will be hidden
            if results.platform_errors.has_errors?
              yield copy_hash_errors_and_options( Hoodoo::Client::AugmentedHash.new, results )
            end

            # Done!
            break

          end

        end
      end

      private

      def copy_hash_errors_and_options( dest, src )
        dest.set_platform_errors( src.platform_errors )
        dest.response_options = src.response_options.dup
        dest
      end

    end
  end
end
