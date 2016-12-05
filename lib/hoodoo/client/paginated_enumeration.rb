########################################################################
# File::    paginated_enumeration.rb
# (C)::     Loyalty New Zealand 2016
#
# Purpose:: A module that adds support for enumeration over paginated
#           resources.
# ----------------------------------------------------------------------
#           29-Sep-2016 (DJO): Created.
########################################################################

module Hoodoo
  class Client # Just used as a namespace here

    # Ruby mixin providing an enumeration mechanism, allowing the
    # caller to iterate over all the resource instances in the list,
    # automatically performing the necessary pagination behind the scenes.
    #
    module PaginatedEnumeration

      # Proc called by enumerate_all to provide the next 'page' of values
      # to be enumerated through. Returns an Hoodoo::Client::AugmentedArray.
      #
      attr_accessor :next_page_proc

      # Yields each resource instance, automatically paginating
      # through the entire set of resources.
      #
      # Provide a block to process each resource instance. For example:
      #
      #     results = members.list(:search => { :surname => 'Smith' } ).enumerate_all do | member |
      #       if member.platform_errors.has_errors?
      #         .. deal with error ...
      #         break
      #       else
      #         .. process member ...
      #       end
      #     end
      #
      # Each iteration yields a Hoodoo::Client::AugmentedHash representation of
      # the requested resource instance. The caller must check for errors on
      # the value yielded with each iteration, as per the example above.
      #
      def enumerate_all

        raise "Must provide a block to enumerate_all" unless block_given?

        # The first set of results is in 'this' AugmentedArray
        results = self

        loop do

          if results.size > 0

            if results.platform_errors.has_errors?
              raise 'Hoodoo::Client::PaginatedEnumeration#enumerate_all: Unexpected internal state combination of results set and results error indication'
            end

            # Yield a resource at a time to the caller
            #
            # Note: An inter-resource call in a single service returns each
            #       resource as a Hash, which must be converted to AugmentedHash
            results.each do | result |
              yield to_augmented_hash(result)
            end
            results = next_page_proc.call()
          else
            # Return errors in an (empty) AugmentedHash
            if results.platform_errors.has_errors?
              yield copy_hash_errors_and_options( Hoodoo::Client::AugmentedHash.new, results )
            end
            break
          end

        end

      end

      private

      # Convert a Hash to an AugmentedHash
      def to_augmented_hash( src )
        src.is_a?( Hoodoo::Client::AugmentedHash ) ? src : Hoodoo::Client::AugmentedHash[ src ]
      end

      # Copy the platform_errors and response_options from src -> dest
      def copy_hash_errors_and_options( dest, src )
        dest.set_platform_errors( src.platform_errors )
        dest.response_options = src.response_options.dup if src.response_options
        dest
      end

    end
  end
end
