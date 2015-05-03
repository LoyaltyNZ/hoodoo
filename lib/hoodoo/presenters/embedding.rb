########################################################################
# File::    embedding.rb
# (C)::     Loyalty New Zealand 2015
#
# Purpose:: Light weight, simple support for basic embed and reference
#           operations that help reduce service reliance on "knowing"
#           exactly how to structure such data / avoid inconsistency.
# ----------------------------------------------------------------------
#           29-Apr-2015 (ADH): Created.
########################################################################

module Hoodoo
  module Presenters

    # The Embedding namespace collects classes that assist with rendering
    # embedded resource data.
    #
    module Embedding

      # The Embeddable base class should not be instantiated directly.
      # It provides common functionality for
      # Hoodoo::Presenters::Embedding::Embeds and
      # Hoodoo::Presenters::Embedding::References - use those instead.
      #
      class Embeddable

        # Create an instance.
        #
        def initialize
          @hash = {}
        end

        # Add a singlular resource (for embedding) or UUID (for referencing)
        # to an embed or reference assembly.
        #
        # +key+:: The key to use in the resource representation leading to
        #         the embedded resource object or UUID string. Typically
        #         follows a singular name convention in your resource API
        #         field language of choice, e.g. "member" (an API where the
        #         resource names and fields are in English), "mitglied" (an
        #         API described in German).
        #
        #         This key must match the value specified in the query string
        #         of a request in order to ask for the thing in question to
        #         be embedded / referenced.
        #
        # +rendered_resource_or_uuid+:: A rendered resource representation
        #         in full, or a resource UUID String.
        #
        def add_one( key, rendered_resource_or_uuid )
          validate_one( rendered_resource_or_uuid )
          @hash[ key ] = rendered_resource_or_uuid
        end

        # Add a collection of resources (for embedding) or UUIDs (for
        # referencing) to an embed or reference assembly.
        #
        # +key+:: The key to use in the resource representation leading to
        #         the embedded resource object or UUID string array. Typically
        #         follows a plural name convention in your resource API field
        #         language of choice, e.g. "members" (an API where the
        #         resource names and fields are in English), "mitglieder" (an
        #         API described in German).
        #
        #         This key must match the value specified in the query string
        #         of a request in order to ask for the things in question to
        #         be embedded / referenced.
        #
        # +array_of_rendered_resources_or_uuids+:: An Array of rendered
        #         resource representations in full, or an Array of resource
        #         UUID Strings.
        #
        def add_many( key, array_of_rendered_resources_or_uuids )
          validate_many( array_of_rendered_resources_or_uuids )
          @hash[ key ] = array_of_rendered_resources_or_uuids
        end

        # Delete all data associated with the given key.
        #
        # +key+:: As provided to a prior call to #add_one or #add_many. Has no
        #         side effects if the key has not been previously used in such
        #         a call; no error is raised in this case either.
        #
        def remove( key )
          @hash.delete( key )
        end

        # Returns a Hash where keys are the keys provided in calls to #add_one
        # or #add_many and values are the values provided to those same
        # corresponding calls. Returns an empty Hash if no such calls have
        # been made or if all the keys were subsequently removed with #remove.
        #
        def retrieve
          @hash
        end
      end

      # Instantiate this class and add one, or an Array of fully rendered
      # resource objects to it via the API described in the base class,
      # Hoodoo::Presenters::Embedding::Embeddable. You can then pass it to
      # the likes of Hoodoo::Presenters::Base#render_in via the +options+
      # parameter to have the embed data included in the fully rendered end
      # result.
      #
      # When a request arrives to embed data for a particular resource or
      # list of resources (in which case, do the following for each item in
      # that list):
      #
      # * Render the embedded resource(s)
      # * Create an instance of this class
      # * Add the rendered resource representations using this class's API
      # * Use Hoodoo::Presenters::Base#render_in to render the final, target
      #   resource, passing in the embed collection via the +options+ Hash.
      #
      # Simple example:
      #
      #     embeds = Hoodoo::Presenters::Embedding::Embeds.new
      #     embeds.add_one( 'balance', rendered_balance )
      #     embeds.add_many( 'vouchers', rendered_voucher_array )
      #
      class Embeds < Embeddable

        public

          # Returns the top-level resource key used for reference data, as per
          # the API documentation - which is the String +_embed+.
          #
          def resource_key
            '_embed'
          end

        protected

          # Called from #add_one in the base class to make sure the right data
          # is being supplied. Raises an exception if it gets worried.
          #
          # +thing+:: The value that'll be stored; should be a Hash.
          #
          def validate_one( thing )
            unless thing.is_a?( ::Hash )
              raise "Hoodoo::Presenters::Embedding::Embeds\#add_one requires a rendered resource Hash, but was given an instance of #{ thing.class }"
            end
          end

          # Called from #add_many in the base class to make sure the right data
          # is being supplied. Raises an exception if it gets worried.
          #
          # +thing+:: The value that'll be stored; should be an Array of Hashes
          #           but only the first array entry is checked, for speed.
          #
          def validate_many( thing )
            unless thing.is_a?( ::Array )
              raise "Hoodoo::Presenters::Embedding::Embeds\#add_many requires an Array, but was given an instance of #{ thing.class }"
            end

            unless thing[ 0 ].nil? || thing[ 0 ].is_a?( ::Hash )
              raise "Hoodoo::Presenters::Embedding::Embeds\#add_many requires an Array of rendered resource Hashes, but the first Array entry is an instance of #{ thing[ 0 ].class }"
            end
          end

      end

      # Instantiate this class and add one, or an Array of UUID strings via
      # the API described in the base class,
      # Hoodoo::Presenters::Embedding::Embeddable. You can then pass it to
      # the likes of Hoodoo::Presenters::Base#render_in via the +options+
      # parameter to have the reference data included in the fully rendered
      # end result.
      #
      # When a request arrives to reference UUID data for a particular
      # resource or list of resources (in which case, do the following for
      # each item in that list):
      #
      # * Obtain the referenced resource UUID(s)
      # * Create an instance of this class
      # * Add the UUIDs using this class's API
      # * Use Hoodoo::Presenters::Base#render_in to render the final, target
      #   resource, passing in the reference collection via the +options+
      #   Hash.
      #
      # Simple example:
      #
      #     references = Hoodoo::Presenters::Embedding::References.new
      #     references.add_one( 'member', member_uuid )
      #     references.add_many( 'memberships', array_of_membership_uuids )
      #
      class References < Embeddable

        public

          # Returns the top-level resource key used for reference data, as per
          # the API documentation - which is the String +_reference+.
          #
          def resource_key
            '_reference'
          end

        protected

          # Called from #add_one in the base class to make sure the right data
          # is being supplied. Raises an exception if it gets worried.
          #
          # +thing+:: The value that'll be stored; should be a valid UUID.
          #
          def validate_one( thing )
            unless Hoodoo::UUID.valid?( thing )
              raise 'Hoodoo::Presenters::Embedding::References#add_one requires a valid UUID String, but the given value is invalid'
            end
          end

          # Called from #add_many in the base class to make sure the right data
          # is being supplied. Raises an exception if it gets worried.
          #
          # +thing+:: The value that'll be stored; should be an Array of valid
          #           UUIDs, but only the first array entry is checked, for
          #           speed.
          #
          def validate_many( thing )
            unless thing.is_a?( ::Array )
              raise "Hoodoo::Presenters::Embedding::References\#add_many requires an Array, but was given an instance of #{ thing.class }"
            end

            unless thing[ 0 ].nil? || Hoodoo::UUID.valid?( thing[ 0 ] )
              raise 'Hoodoo::Presenters::Embedding::References#add_many requires an Array of valid UUID strings, but the first Array entry is invalid'
            end
          end

      end

    end
  end
end
