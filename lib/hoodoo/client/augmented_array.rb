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

    # Ruby standard library Array subclass which mixes in
    # Hoodoo::Client::AugmentedBase. See that for details.
    #
    class AugmentedArray < ::Array
      include Hoodoo::Client::AugmentedBase

      # For lists, the (optional) total size of the data set, of which
      # the contents of this Array will often only represent a single
      # page. If unknown, the value is +nil+, but as an alternative, an
      # estimated size may be available in #estimated_dataset_size.
      #
      attr_accessor :dataset_size

      # For lists, the (optional) estimated size of the data set, of
      # which the contents of this Array will often only represent a
      # single page. If unknown, the value is +nil+. The accuracy of
      # the estimation is unknown.
      #
      attr_accessor :estimated_dataset_size

      attr_accessor :description_of_request, :endpoint

      def enumerate_all

        # If an error occurs in the first call we don't get this - messy
        if description_of_request.nil?
          r = Hoodoo::Client::AugmentedHash.new
          r.set_platform_errors( self.platform_errors )
          r.response_options = self.response_options.dup
          yield r
          return
        end

        raise "Must provide a block to paginate" unless block_given?
        raise "Missing description_of_request" unless description_of_request
        raise "Missing endpoint" unless endpoint
        raise "Calling enumerate_all only valid for 'list' action, not #{description_of_request.action} " unless description_of_request.action == :list

        batch_query_hash = description_of_request.query_hash.nil? ? {} : description_of_request.query_hash.dup
        batch_query_hash[:limit] = 50 unless batch_query_hash.has_key? :limit
        offset = 0

        loop do
          batch_query_hash[:offset] = offset
          results = endpoint.list(batch_query_hash)

          # Yield 0..1 resource at a time, in the form returned by GET which
          # also returns 0..1 resource as an AugmentedHash
          results.each do |r|
            r.set_platform_errors( results.platform_errors )
            r.response_options = results.response_options.dup
            yield r
          end

          # If service returns no results, but returns an error, we must yield
          # that error to the caller, otherwise it woule be hidden
          if results.platform_errors.has_errors? && results.size == 0
            r = Hoodoo::Client::AugmentedHash.new
            r.set_platform_errors( results.platform_errors )
            r.response_options = results.response_options.dup
            yield r
          end

          if results.size == 0 || results.platform_errors.has_errors?
            break
          end

          # Resource implementation decides the :batch_size
          batch_size = [1, results.size].max

          offset += batch_size
        end
      end

    end

  end
end
