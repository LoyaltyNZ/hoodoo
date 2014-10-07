module ApiTools
  module Presenters
    # A JSON array schema member
    class Array < ApiTools::Presenters::Field

      include ApiTools::Presenters::BaseDSL

      # The properties of this object, an +array+ of +Field+ instances.
      attr_accessor :properties

      # Check if data is a valid Array and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.count > 0
        return [] if !@required and data.nil?

        if data.is_a? ::Array
          data.each_with_index do |item, index|
            @properties.each do |name, property|
              rdata = (item.is_a?(::Hash) and item.has_key?(name)) ? item[name] : nil
              indexed_path = "#{full_path(path)}[#{index}]"
              errors += property.validate(rdata, indexed_path )
            end
          end
        else
          errors << {:code=> 'generic.invalid_array', :message=>"Field `#{full_path(path)}` is an invalid array", :reference => full_path(path)}
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

        # This relies on pass-by-reference; we'll update 'array' later.

        array = []
        path  = super( array, target )

        # No defined schema for the array contents? Just use the data as-is;
        # we can do no validation. Have to hope the caller has given us data
        # that would be valid as JSON. No data at all? Do nothing. Else
        # run through the schema properties for each entry and validate them.

        if data.nil?
          return

        elsif @properties.nil?
          # Must modify existing instance of 'array', so use 'push()'
          array.push( *data )

        else
          data.each do | item |
            subtarget = {}

            @properties.each do | name, property |
              property.render( item[ name ], subtarget )
            end

            # Must modify existing instance of 'array', so use 'push()'
            array.push( read_at_path( subtarget, path ) )
          end
        end
      end
    end
  end
end
