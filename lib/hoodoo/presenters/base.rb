########################################################################
# File::    base_presenter.rb
# (C)::     Loyalty New Zealand 2014
#
# Purpose:: Schema-based data rendering and validation.
# ----------------------------------------------------------------------
#           02-Dec-2014 (ADH): Merge of DocumentedPresenter code into
#                              Base.
########################################################################

module Hoodoo
  module Presenters

    # Base functionality for JSON validation and presenter (rendering) layers.
    # Subclass this to define a schema against which validation of inbound data
    # or rendering of outbound data can be performed. Call #schema in the
    # subclass to declare, via the DSL, the shape of the schema.
    #
    class Base

      # Define the JSON schema for validation.
      #
      # &block:: Block that makes calls to the DSL defined in
      #          Hoodoo::Presenters::BaseDSL in order to define the schema.
      #
      def self.schema( &block )
        @schema = Hoodoo::Presenters::Object.new
        @schema.instance_eval( &block )
        @schema_definition = block
      end

      # Given some data that should conform to the subclass presenter's schema,
      # render it to go from the input Ruby Hash, to an output Ruby Hash which
      # will include default values - if any - present in the schema and will
      # drop input fields not present in that schema. In essence, this takes
      # data which may have been programatically generated and sanitises it to
      # produce valid, with-defaults guaranteed valid output.
      #
      # Any field with a schema giving a default value will only appear should
      # a value for that field be _omitted_ in the input data. If the data
      # provides, for example, an explicit +nil+ value then a corresponding
      # explicit +nil+ will be rendered, regardless of defaults.
      #
      # For belt-and-braces, unless subsequent profiling shows performance
      # issues, callers should call #validate first to self-check their internal
      # data against the schema prior to rendering. That way, coding errors
      # will be discovered immediately, rather than hidden / obscured by the
      # rendered sanitisation.
      #
      # Since rendering top-level +nil+ is not valid JSON, should +nil+ be
      # provided as input, it'll be treated as an empty hash ("+{}+") instead.
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
        data   = data || {}

        @schema.render( data, target )

        # Common fields are added after rendering the data in case there are
        # any same-named field collisions - platform defaults should take
        # precedence, overwriting previous definitions intentionally.

        unless ( uuid.nil? )

          raise "Can't render a Resource with a nil 'created_at'" if created_at.nil?

          # Field "kind" is taken from the class name; this is a class method
          # so "self.name" yields "Hoodoo::Data::Resources::..." or similar.
          # Split on "::" and take the last part as the Resource kind.

          target.merge!( {
            'id'         => uuid,
            'kind'       => self.name.split( '::' ).last,
            'created_at' => Time.parse( created_at.to_s ).utc.iso8601
          } )

          target[ 'language' ] = language if self.is_internationalised?()

        end

        return target
      end

      # Is the given rendering of a resource valid? Returns an array of
      # Error Primitive types (as hashes); this will be empty if the data
      # given is valid.
      #
      # +data+:: Ruby Hash representation of JSON data that is to be validated
      #          against 'this' schema. Keys must be Strings, not Symbols.
      #
      # +as_resource+:: Check Resource common fields - +id+, +kind+,
      #                 +created_at+ and (for an internationalised resource)
      #                 +language+. Otherwise, only basic data schema is
      #                 examined. Optional; default is +false+.
      #
      def self.validate( data, as_resource = false )
        errors = @schema.validate( data )

        if as_resource
          common_fields = {
            'id'         => data[ :id         ],
            'created_at' => data[ :created_at ],
            'kind'       => data[ :kind       ]
          }

          if self.is_internationalised?
            common_fields[ 'internationalised' ] = data[ 'internationalised' ]
            Hoodoo::Presenters::CommonResourceFields.get_schema.properties[ 'language' ].required = true
          end

          errors.merge!( Hoodoo::Presenters::CommonResourceFields.validate( data, false ) )

          Hoodoo::Presenters::CommonResourceFields.get_schema.properties[ 'language' ].required = false
        end

        return errors
      end

      # Does this presenter use internationalisation? Returns +true+ if so,
      # else +false+.
      #
      def self.is_internationalised?
        @schema.is_internationalised?
      end

      # Return the schema graph. See also #get_schema_definition.
      #
      def self.get_schema
        @schema
      end

      # Read back the block that defined the schema graph. See also
      # #get_schema.
      #
      def self.get_schema_definition
        @schema_definition
      end
    end
  end
end