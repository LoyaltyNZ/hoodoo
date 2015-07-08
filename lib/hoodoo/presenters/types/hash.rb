module Hoodoo
  module Presenters
    # A JSON hash schema member
    class Hash < Hoodoo::Presenters::Field

      include Hoodoo::Presenters::BaseDSL

      # Hash DSL: Define a specific named key that is allowed (or even required)
      # in the hash. The optional block uses Hoodoo::Presenters::BaseDSL to
      # describe the required form of the key's value. If the block is omitted,
      # any value is permitted.
      #
      # The singular #key method is useful when you want to describe an object
      # which has known permitted keys yielding to required value types. For
      # example, you may have a Hash which defines configuration data for a
      # variety of fixed, known types, with the Hash keys being the type name.
      # See Hoodoo::Data::Types::CalculatorConfiguration for an example.
      #
      # Example:
      #
      #     hash :nested_object do
      #       key :this_key_is_optional do
      #         text :text_value
      #         string :string_value, :length => 16
      #       end
      #
      #       # ...multiple calls would be made to #key usually, to define
      #       # each allowed key.
      #
      #     end
      #
      # ...defines something that this JSON would validate against:
      #
      #     {
      #       "nested_object": {
      #         "this_key_is_optional": {
      #           "text_value": "some arbitrary length string",
      #           "string_value": "I'm <= 16 chars"
      #         }
      #       }
      #     }
      #
      # This JSON would not validate as it includes an unrecognised key:
      #
      #     {
      #       "nested_object": {
      #         "this_key_is_unknown": '', // (...any value at all...)
      #         "this_key_is_optional": {
      #           "text_value": "Some arbitrary length string",
      #           "string_value": "I'm <= 16 chars"
      #         }
      #       }
      #     }
      #
      def key( name, options = {}, &block )
        if @specific == false
          raise "Can't use \#keys and then \#key in the same hash definition - use one or the other"
        end

        # If we're defining specific keys and some of those keys have fields
        # with defaults, we need to merge those up to provide a whole-key
        # equivalent default. If someone renders an empty hash they expect a
        # specific key with some internal defaults to be rendered; doing this
        # amalgamation up to key level is the easiest way to handle that.

        if options.has_key?( :default )
          @has_default = true

          @default    ||= {}
          @default.merge!( Hoodoo::Utilities.stringify( options[ :default ] ) )
        end

        @specific = true

        klass = block_given? ? Hoodoo::Presenters::Object : Hoodoo::Presenters::Field
        prop  = property( name, klass, options, &block )

        if prop && prop.respond_to?( :is_internationalised? ) && prop.is_internationalised?
          internationalised()
        end
      end

      # Hash DSL: Define general parameters allowed for keys in a Hash and, if
      # a block is given, use Hoodoo::Presenters::BaseDSL to describe how any
      # of the values in the Hash must look.
      #
      # +options+:: A +Hash+ of options - currently only +:length => [n]+ is
      #             supported, which describes the maximum permitted length of
      #             the key. If this option is omitted, keys can be any length.
      #
      # Example:
      #
      #     hash :nested_object do
      #       keys :length => 4 do
      #         text :text_value
      #       end
      #
      #       # ...only one call is made to #keys, because it defines the
      #       # permitted form of all keys and values for the whole Hash.
      #
      #     end
      #
      # ...defines a Hash with keys that have a maximum string length of 4
      # characters (inclusive) and simple object values with just a single text
      # field. This JSON would validate against the definition:
      #
      #     {
      #       "nested_object": {
      #         "one": {
      #           "text_value": "Some arbitrary length string"
      #         },
      #         "two": {
      #           "text_value": "Another arbitrary length string"
      #         }
      #       }
      #     }
      #
      # This JSON would not validate as one of the keys is too long:
      #
      #     {
      #       "nested_object": {
      #         "one": {
      #           "text_value": "Some arbitrary length string"
      #         },
      #         "a_very_long_key": {
      #           "text_value": "Another arbitrary length string"
      #         }
      #       }
      #     }
      #
      # This JSON would not validate as the value's object format is wrong:
      #
      #     {
      #       "nested_object": {
      #         "one": {
      #           "text_value": 11
      #         }
      #       }
      #     }
      #
      def keys( options = {}, &block )
        unless @specific.nil?
          raise "Can't use \#key and then \#keys in the same hash definition, or use \#keys more than once"
        end

        if options.has_key?( :default )
          raise "It doesn't make sense to specify a default for unknown source data keys, since every key that's present in the source data has an associated value by definition, even if that value is nil"
        end

        @specific = false

        klass = options.has_key?( :length ) ? Hoodoo::Presenters::String : Hoodoo::Presenters::Text
        property('keys', klass, options)

        klass = block_given? ? Hoodoo::Presenters::Object : Hoodoo::Presenters::Field
        prop  = property( 'values', klass, {}, &block )

        if prop && prop.respond_to?( :is_internationalised? ) && prop.is_internationalised?
          internationalised()
        end
      end

      # The properties of this object, a +hash+ of +Field+ instances.
      attr_accessor :properties

      # Check if data is a valid Hash and return a Hoodoo::Errors instance.
      #
      def validate( data, path = '' )
        errors = super( data, path )
        return errors if errors.has_errors? || ( ! @required && data.nil? )

        if data.is_a?( ::Hash )

          # No hash entry schema? No hash entry validation, then.
          #
          unless @properties.nil?
            if @specific == true

              allowed_keys      = @properties.keys
              unrecognised_keys = data.keys - allowed_keys

              unless unrecognised_keys.empty?
                errors.add_error(
                  'generic.invalid_hash',
                  :message   => "Field `#{ full_path( path ) }` is an invalid hash due to unrecognised keys `#{ unrecognised_keys.join( ', ' ) }`",
                  :reference => { :field_name => full_path( path ) }
                )
              end

              data.each do | key, value |
                property = @properties[ key ]
                errors.merge!( property.validate( value, full_path( path ) ) ) unless property.nil?
              end

              @properties.each do | name, property |
                if property.required && ! data.has_key?( name )
                  local_path = full_path(path) + '.' + name

                  errors.add_error(
                    'generic.required_field_missing',
                    :message   => "Field `#{local_path}` is required",
                    :reference => { :field_name => local_path }
                  )
                end
              end

            else

              keys_property   = @properties[ 'keys'   ]
              values_property = @properties[ 'values' ]

              if keys_property.required && data.empty?

                errors.add_error(
                  'generic.required_field_missing',
                  :message   => "Field `#{ full_path( path ) }` is required (Hash, if present, must contain at least one key)",
                  :reference => { :field_name => full_path( path ) }
                )

              else

                # Need to adjust the above property names for each of the
                # unknown-named keys coming into this generic key hash. That
                # way, errors are reported at the correct "path", including the
                # 'dynamic' incoming hash key name.

                data.each do | key, value |
                  local_path = full_path( path )

                  # So use the "keys property" as a validator for the format
                  # (i.e. just length, in practice) of the current key we're
                  # examining in the data from the caller. Use the "values
                  # property" to validate the value in the data hash. Both are
                  # temporarily renamed to match the key in the client data so
                  # that field paths shown in errors will be correct.

                    keys_property.rename( key )
                  values_property.rename( key )

                  errors.merge!(   keys_property.validate( key, local_path ) )
                  errors.merge!( values_property.validate( value, local_path ) )
                end

                  keys_property.rename(   'keys' )
                values_property.rename( 'values' )

              end
            end
          end # 'unless @properties.nil?'

        else  # 'if data.is_a?( ::Hash )'
          errors.add_error(
            'generic.invalid_hash',
            :message   => "Field `#{ full_path( path ) }` is an invalid hash",
            :reference => { :field_name => full_path( path ) }
          )
        end

        errors
      end

      # Render a hash into the target hash based on the internal state that
      # describes this instance's current path (position in the heirarchy of
      # nested schema entities).
      #
      # +data+::   The Hash to render.
      # +target+:: The Hash that we render into. A "path" of keys leading to
      #            nested Hashes is built via +super()+, with the final
      #            key entry yielding the rendered hash.
      #
      def render( data, target )

        # Data provided is explicitly nil or not a hash? Don't need to render
        # anything beyond 'nil' at the field (the not-hash case covers nil and
        # covers invalid input, which is treated as nil).
        #
        return super( nil, target ) unless data.is_a?( ::Hash )

        # This relies on pass-by-reference; we'll update 'hash' later.

        hash = {}
        path = super( hash, target )

        # No defined schema for the hash contents? Just use the data as-is;
        # we can do no validation. Have to hope the caller has given us data
        # that would be valid as JSON. Otherwise, use the key definitions.

        if @properties.nil?
          hash.merge!( data )

        else
          subtarget = {}

          if @specific == true

            @properties.each do | name, property |
              name    = name.to_s
              has_key = data.has_key?( name )

              next unless has_key || property.has_default?()

              property.render( has_key ? data[ name ] : property.default, subtarget )
            end

          else

            # The "keys :default => ..." part of the DSL is theoretically
            # possible but meaningless. The principle everywhere else is that
            # if the input data has an explicit "nil" then the output data has
            # the same. In that case, the input data hash either has non-nil
            # or nil *explicit* values, so there are no conditions under which
            # we would apply a default.

            values_property = @properties[ 'values' ]

            # As with validation, have to temporarily rename the above property
            # (and update its path) so that we render under the correct key
            # name, those names coming from the caller-supplied hash and thus
            # not known at any time other than right now.

            data.each do | key, value |
              values_property.rename( key )
              values_property.render( value, subtarget )
            end

            values_property.rename( 'values' )
          end

          rendered = read_at_path( subtarget, path )
          hash.merge!( rendered ) unless rendered.nil?
        end
      end

      # Invoke a given block, passing this item; call recursively for any
      # defined sub-fields too. See Hoodoo::Presenters::Base#walk for why.
      #
      # &block:: Mandatory block, which is passed 'self' when called.
      #
      def walk( &block )
        block.call( self )

        unless @properties.nil?
          if @specific == true

            @properties.each do | name, property |
              property.walk( &block )
            end

          else

            values_property = @properties[ 'values' ]
            values_property.properties.each do | name, property |
              property.walk( &block )
            end unless values_property.properties.nil?

          end
        end
      end
    end
  end
end
