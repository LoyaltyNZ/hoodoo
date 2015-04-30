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
      # This is quite a low-level call. For a higher level renderer which
      # Hoodoo service resource implementations will probably want to use for
      # returning resource representations in responses, see ::render_in.
      #
      # +data+::       Hash to be represented. Data within this is compared
      #                against the schema being called to ensure that correct
      #                information is returned and unknown data is ignored.
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

      # A higher level version of ::render, typically called from Hoodoo
      # services in their resource implementation code.
      #
      # As with ::render, data is rendered according to the schema of the
      # object the ::render_in message is sent to. Options specify things like
      # UUID and created-at date. Language information for internationalised
      # fields can be given, but if omitted comes from the given request
      # context data.
      #
      # Additional facilites exist over and above ::render - security scoping
      # information in the resource via its +secured_with+ field is made
      # available through options (see below), along with support for embedded
      # or referenced resource information.
      #
      # +context+:: A Hoodoo::Services::Context instance, which is usually the
      #             value passed to a service implementation in calls like
      #             Hoodoo::Services::Implementation#list or
      #             Hoodoo::Services::Implementation#show.
      #
      # +data+::    Hash to be represented. Data within this is compared
      #             against the schema being called to ensure that correct
      #             information is returned and unknown data is ignored.
      #
      # +options+:: Options hash, see below.
      #
      # The options keys are Symbols, used as follows:
      #
      # +uuid+::         Same as the +uuid+ parameter to ::render, except
      #                  mandatory.
      #
      # +created_at+::   Same as the +created_at+ parameter to ::render, except
      #                  mandatory.
      #
      # +language+::     Optional value for resource's +language+ field; taken
      #                  from the +context+ parameter if omitted.
      #
      # +embeds+::       A Hoodoo::Presenters::Embedding::Embeds instance that
      #                  contains (fully rendered) resources which are to be
      #                  embedded in this rendered representation. Optional.
      #
      # +references+::   A Hoodoo::Presenters::Embedding::References instance
      #                  that contains UUIDs which are to be embedded in this
      #                  rendered representation as references. Optional.
      #
      # +secured_with+:: An ActiveRecord::Base subclass instance where the
      #                  model class includes a +secure_with+ declaration. As
      #                  per documentation for
      #                  Hoodoo::ActiveRecord::Secure::ClassMethods#secure and
      #                  Hoodoo::ActiveRecord::Secure::ClassMethods#secure_with,
      #                  this leads (potentially) to the generation of the
      #                  +secured_with+ field and object value in the rendered
      #                  resource data.
      #
      def self.render_in( context, data, options )
        uuid         = options[ :uuid         ]
        created_at   = options[ :created_at   ]
        language     = options[ :language     ] || context.request.locale
        secured_with = options[ :secured_with ]
        embeds       = options[ :embeds       ]
        references   = options[ :references   ]

        target = self.render( data, uuid, created_at, language )

        if secured_with.is_a?( ActiveRecord::Base )
          result_hash     = {}
          extra_scope_map = class_variable_defined?( :@@nz_co_loyalty_hoodoo_secure_with ) ?
                                 class_variable_get( :@@nz_co_loyalty_hoodoo_secure_with ) :
                                 nil

          extra_scope_map.each do | model_field_name, key_or_options |
            resource_field = if key_or_options.is_a?( Hash )
              next if key_or_options[ :hide_from_resource ] == true
              key_or_options[ :resource_field_name ] || model_field_name
            else
              key_or_options
            end

            secured_with[ resource_field ] = model.send( model_field_name )
          end unless extra_scope_map.nil?

          target[ 'secured_with' ] = result_hash unless result_hash.empty?
        end

        target[ '_embed'     ] = embeds.retrieve()     unless embeds.nil?
        target[ '_reference' ] = references.retrieve() unless references.nil?

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