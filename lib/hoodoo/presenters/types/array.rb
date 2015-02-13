module Hoodoo
  module Presenters
    # A JSON array schema member
    class Array < Hoodoo::Presenters::Field

      include Hoodoo::Presenters::BaseDSL

      # The properties of this object, an +array+ of +Field+ instances.
      attr_accessor :properties

      # Check if data is a valid Array and return a Hoodoo::Errors instance
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.has_errors? || (!@required and data.nil?)

        if data.is_a? ::Array
          # No array entry schema? No array entry validation, then.
          unless @properties.nil?
            data.each_with_index do |item, index|
              @properties.each do |name, property|
                rdata = (item.is_a?(::Hash) and item.has_key?(name)) ? item[name] : nil
                indexed_path = "#{full_path(path)}[#{index}]"
                errors.merge!( property.validate(rdata, indexed_path ) )
              end
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
      def render(data, target)

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

        if @properties.nil?
          # Must modify existing instance of 'array', so use 'push()'
          array.push( *data )

        else
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
              name        = name.to_s
              has_key     = item.has_key?( name )
              has_default = property.has_default?()

              next unless has_key || has_default

              property.render( has_key ? item[ name ] : property.default, subtarget )
            end

            rendered = subtarget.empty? ? {} : read_at_path( subtarget, path )

            # Must modify existing instance of 'array', so use 'push()'
            array.push( rendered )
          end
        end
      end
    end
  end
end
