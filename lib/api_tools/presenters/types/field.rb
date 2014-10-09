module ApiTools
  module Presenters
    # A JSON schema member
    class Field

      # The name of the field
      attr_accessor :name
      # +true+ if the field is required
      attr_accessor :required
      # Default value, if supplied
      attr_accessor :default
      # Mapping to and from model
      attr_accessor :mapping

      # Initialize a Field instance with the appropriate name and options
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def initialize(name, options = {})
        @name = name
        @required = options.has_key?(:required) ? options[:required] : false
        @default = options.has_key?(:default) ? options[:default] : nil
        @mapping = options.has_key?(:mapping) ? options[:mapping] : nil
        @path = options.has_key?(:path) ? options[:path] : []
      end

      # Check if data is required and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = []
        if data.nil? and @required
          errors << {:code=> 'generic.required_field_missing', :message=>"Field `#{full_path(path)}` is required", :reference => full_path(path)}
        end
        errors
      end

      def parse(data, target)
        root = data
        (@mapping.nil? ? @path : @mapping).each do |element|
          return nil unless root.has_key?(element)
          root = root[element]
        end
        target[@name] = root
      end

      # Dive down into a given hash along path arrays +@mapping+ or +@path+,
      # building new hash entries if necessary at each path level until the
      # last one. At that last level, assign the given object.
      #
      # +data::     The object to build at the final path entry - usually an
      #             empty Array or Hash.
      #
      # +target+::  The Hash (may be initially empty) in which to build the
      #             path of keys from internal data +@mapping+ or +@path+.
      #
      # Returns the full path array that was used (a clone of +@mapping+ or
      # +@path+).
      #
      def render(data, target)
        root  = target
        path  = ( @mapping.nil? ? @path : @mapping ).clone
        final = path.pop

        path.each do | element |
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
          from_target = from_target[ element ]
        end

        return from_target
      end

    end
  end
end