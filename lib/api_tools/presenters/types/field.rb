module Hoodoo
  module Presenters
    # A JSON schema member
    class Field

      # The name of the field
      attr_accessor :name
      # +true+ if the field is required
      attr_accessor :required
      # Default value, if supplied
      attr_accessor :default

      # Initialize a Field instance with the appropriate name and options
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def initialize(name, options = {})
        @name     = name.to_s
        @required = options.has_key?( :required ) ? options[ :required ] : false
        @path     = options.has_key?( :path     ) ? options[ :path     ] : []

        if options.has_key?( :default )
          @has_default = true
          @default     = Hoodoo::Utilities.stringify( options[ :default ] )
        else
          @has_default = false
          @default     = nil
        end
      end

      # Does this property have a defined default (which may be defined as
      # +nil+) rather than having no defined value (+nil+ or otherwise)?
      # Returns +true+ if it has a default, +false+ if it has no default.
      #
      def has_default?
        !! @has_default
      end

      # Check if data is required and return an Hoodoo::Errors instance
      def validate(data, path = '')
        errors = Hoodoo::Errors.new

        if data.nil? and @required
          errors.add_error(
            'generic.required_field_missing',
            :message   => "Field `#{ full_path( path ) }` is required",
            :reference => { :field_name => full_path( path ) }
          )
        end

        errors
      end

      # Dive down into a given hash along path array +@path+, building new hash
      # entries if necessary at each path level until the last one. At that
      # last level, assign the given object.
      #
      # +data::     The object to build at the final path entry - usually an
      #             empty Array or Hash.
      #
      # +target+::  The Hash (may be initially empty) in which to build the
      #             path of keys from internal data +@path+.
      #
      # Returns the full path array that was used (a clone of +@path+).
      #
      def render(data, target)

        return if @name.empty?

        root  = target
        path  = @path.clone
        final = path.pop.to_s

        path.each do | element |
          element = element.to_s
          root[ element ] = {} unless root.has_key?( element )
          root = root[ element ]
        end

        root[ final ] = data
        return path << final
      end

      # Return the full path and name of this field
      # +path+:: The JSON path or nil, e.g. 'one.two'
      def full_path(path)
        return @name.to_s if path.nil? or path.empty?
        return path.to_s if @name.nil? or @name.empty?
        path+'.'+@name.to_s
      end

    protected

      # Dive down into a given target data hash using the given array of path
      # keys, returning the result at the final key in the path. E.g. if the
      # Hash is "{ :foo => { :bar => { :baz => "hello" } } }" then a path of
      # "[ :foo, :bar ]" would yield "{ :baz => "hello" }".
      #
      def read_at_path( from_target, with_path )
        with_path.each do | element |
          element = element.to_s
          from_target = from_target[ element ]
          break if from_target.nil?
        end

        return from_target
      end

      # Rename a property to the given name. The internal name is changed and
      # the last path entry set to the same name (if a path is present). Paths
      # of sub-properties (if any) are updated with the parent's new name.
      #
      # This is a specialist interface which is intended for internal use
      # under unusual circumstances.
      #
      # +name+:: New property name. Must be a String.
      #
      def rename( name )
        depth = @path.count - 1
        @name = name

        rewrite_path( depth, name )
      end

      # Change the +@path+ array by writing a given value in at a given index.
      # If this property has any sub-properties, then those are recursively
      # updated to change the same depth item to the new name in all of them.
      #
      # +depth+:: Index into +@path+ to make modifications.
      # +name+::  Value to write at that index.
      #
      def rewrite_path( depth, name )
        @path[ depth ] = name if depth >= 0
        return if @properties.nil?

        @properties.each do | property_name, property |
          property.rewrite_path( depth, name )
        end
      end
    end
  end
end