########################################################################
# File::    documented_presenter.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Base class for predefined Type and Resource definitions
#           that inherit the ApiTools::Presenters::BasePresenter methods
#           for parsing, rendering and validation.
# ----------------------------------------------------------------------
#           26-Sep-2014 (ADH): Created.
########################################################################

module ApiTools
  module Data

    # Base class for predefined Type and Resource definitions
    # that inherit the ApiTools::Presenters::BasePresenter methods
    # for parsing, rendering and validation.
    #
    # See the ApiTools::Data::Types and ApiTools::Data::Resources
    # collections of subclasses for more.
    #
    class DocumentedPresenter < ApiTools::Presenters::BasePresenter

      # Define the JSON schema for validation. See also ::schema_definition.
      #
      # &block:: Block that makes calls to the DSL defined by
      #          ApiTools::Data::DocumentedObject.
      #
      def self.schema(&block)
        @schema = ApiTools::Data::DocumentedObject.new
        @schema.instance_eval &block
        @schema_definition = block
      end

      # Read back the block that defined the schema. See also ::schema.
      #
      def self.schema_definition
        @schema_definition
      end

      # Does this presenter use internationalisation?
      #
      def self.is_internationalised?
        @schema.is_internationalised?
      end

      # Return a to-JSON hash that represents this resource.
      #
      # +data+::       Hash or Array (depending on resource's top-level
      #                data container type) to be represented. Data within
      #                this is compared against the schema being called to
      #                ensure that correct information is returned and
      #                unknown data is ignored.
      #
      # +uuid+::       Unique ID of the resource instance that is to be
      #                represented. If nil / omitted, this is assumed to be
      #                a rendering of a type or other non-resource like item.
      #                Otherwise the field is mandatory.
      #
      # +created_at+:: Date/Time of instance creation. Only required if UUID
      #                has been provided. This is a Ruby DateTime instance or
      #                similar, _NOT_ a string!
      #
      # +language+::   Optional language. If the type/resource being rendered
      #                is internationalised but this is omitted, then a value
      #                of "en-nz" is used as a default.
      #
      def self.render( data, uuid = nil, created_at = nil, language = 'en-nz' )
        target = {}

        @schema.render( data, target )

        # Common fields are added after rendering the data in case there are
        # any same-named field collisions - platform defaults should take
        # precedence, overwriting previous definitions intentionally.

        unless ( uuid.nil? )

          raise "Can't render a Resource with a nil 'created_at'" if created_at.nil?

          # Field "kind" is taken from the class name; this is a class method
          # so "self.name" yields "ApiTools::Data::Resources::..." or similar.
          # Split on "::" and take the last part as the Resource kind.

          target.merge!( {
            :id         => uuid,
            :kind       => self.name.split( '::' ).last,
            :created_at => Time.parse( created_at.to_s ).iso8601
          } )

          target[ :language ] = language if self.is_internationalised?()

        end

        return target
      end
    end
  end
end
