module Hoodoo
  module Presenters

    # A JSON Array schema member.
    #
    class Array < Hoodoo::Presenters::Field

      include Hoodoo::Presenters::BaseDSL

      # The properties of this object, an +array+ of +Field+ instances.
      #
      attr_accessor :properties

      # Initialize an Array instance with the appropriate name and options.
      #
      # +name+::    The JSON key.
      # +options+:: A +Hash+ of options, e.g. <tt>:required => true,
      #             :type => :enum, :field_from => [ 1, 2, 3, 4 ]</tt>. If
      #             a +:type+ field is present, the Array contains atomic
      #             types of the given kind. Otherwise, either pass a
      #             block with inner schema DSL calls describing complex
      #             array entry schema, or nothing for no array content
      #             validation. If a block _and_ +:type+ option are
      #             passed, the block is used and option ignored.
      #
      def initialize( name, options = {} )
        super( name, options )

        if options.has_key?( :type )

          # Defining a property via "#property" adds it to the @properties
          # array, but handling of simple Types in array validation and
          # rendering is too different from complex types to use the same
          # code flow; we need the property to be independently used, so
          # extract it into its own instance variable and delete the item
          # from @properties.
          #
          value_klass     = type_option_to_class( options[ :type ] )
          random_name     = Hoodoo::UUID.generate()
          @value_property = property( random_name,
                                      value_klass,
                                      extract_field_prefix_options_from( options ) )

          @properties.delete( random_name )

          # This is approaching a blunt hack. Without it, validation errors
          # will result in e.g. "fields[1].cd2f0a15ec8e4bd6ab1964b25b044e69"
          # in error messages. By using nil, the validation code's JSON path
          # array to string code doesn't include the item, giving the
          # desired result. In addition, the base class Field#render code
          # has an important check for non-nil but empty and bails out, but
          # allows the nil name case to render simple types as expected. A
          # delicate / fragile balance of nil-vs-empty arises.
          #
          @value_property.name = nil

        end
      end

      # Check if data is a valid Array and return a Hoodoo::Errors instance.
      #
      def validate( data, path = '' )
        errors = super( data, path )
        return errors if errors.has_errors? || ( ! @required && data.nil? )

        if data.is_a?( ::Array )

          # A block which defined properties for this instance takes
          # precedence; then check for a ":type" option via "@@value_property"
          # stored in the constructor; then give up and do no validation.
          #
          if @properties.nil? == false && @properties.empty? == false
            data.each_with_index do | item, index |
              @properties.each do | name, property |
                rdata = ( item.is_a?( ::Hash ) && item.has_key?( name ) ) ? item[ name ] : nil
                indexed_path = "#{ full_path( path ) }[#{ index }]"
                errors.merge!( property.validate( rdata, indexed_path ) )
              end
            end
          elsif @value_property.nil? == false
            data.each_with_index do | item, index |
              indexed_path = "#{ full_path( path ) }[#{ index }]"
              errors.merge!( @value_property.validate( item, indexed_path ) )
            end
          end

        else
          errors.add_error(
            'generic.invalid_array',
            :message   => "Field `#{ full_path( path ) }` is an invalid array",
            :reference => { :field_name => full_path( path ) }
          )
        end

        errors
      end

      # Render an array into the target hash based on the internal state that
      # describes this instance's current path (position in the heirarchy of
      # nested schema entities).
      #
      # +data+::   The Array to render.
      # +target+:: The Hash that we render into. A "path" of keys leading to
      #            nested Hashes is built via +super()+, with the final
      #            key entry yielding the rendered array.
      #
      def render( data, target )

        # Data provided is explicitly nil or not an array? Don't need to render
        # anything beyond 'nil' at the field (the not-array case covers nil and
        # covers invalid input, which is treated as nil).

        return super( nil, target ) if ! data.is_a?( ::Array )

        # Otherwise, start looking at rendering array contents (even if the
        # input array is empty). This relies on pass-by-reference; we'll update
        # this specific instance of 'array' later. Call 'super' to render the
        # 'array' instance in place in 'target' straight away...

        array = []
        path  = super( array, target )

        # ...then look at rendering the input entries of 'data' into 'array'.

        if @properties.nil? == false && @properties.empty? == false
          data.each do | item |

            # We have properties defined so array values (in "item") must be
            # Hashes. If non-Hash, treat as if nil; explicit-nil-means-nil.

            unless item.is_a?( ::Hash )
              # Must modify existing instance of 'array', so use 'push()'
              array.push( nil )
              next
            end

            subtarget = {}

            @properties.each do | name, property |
              name    = name.to_s
              has_key = item.has_key?( name )

              next unless has_key || property.has_default?()

              property.render( has_key ? item[ name ] : property.default, subtarget )
            end

            rendered = subtarget.empty? ? {} : read_at_path( subtarget, path )

            # Must modify existing instance of 'array', so use 'push()'
            array.push( rendered )
          end

        elsif @value_property.nil? == false
          data.each do | item |
            subtarget = {}
            @value_property.render( item, subtarget )
            rendered = subtarget.empty? ? nil : read_at_path( subtarget, path ).values.first

            # Must modify existing instance of 'array', so use 'push()'
            array.push( rendered )
          end

        else
          # Must modify existing instance of 'array', so use 'push()'
          array.push( *data )

        end
      end

      # Invoke a given block, passing this item; call recursively for any
      # defined sub-fields too. See Hoodoo::Presenters::Base#walk for why.
      #
      # &block:: Mandatory block, which is passed 'self' when called.
      #
      def walk( &block )
        block.call( self )

        @properties.each do | name, property |
          property.walk( &block )
        end unless @properties.nil?
      end
    end
  end
end
