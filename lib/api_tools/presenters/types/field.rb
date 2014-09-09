module ApiTools
  module Presenters
    # A JSON schema member
    class Field

      # The name of the field
      attr_accessor :name
      # +true+ if the field is required
      attr_accessor :required
      # Mapping to and from model
      attr_accessor :mapping

      # Initialize a Field instance with the appropriate name and options
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def initialize(name, options = {})
        @name = name
        @required = options.has_key?(:required) ? options[:required] : false
        unless name.nil?
          @mapping = options.has_key?(:mapping) ? options[:mapping] : name.to_sym
        end
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
        path = @mapping.clone
        root = data
        path.each do |element|
          return nil unless root.has_key?(element)
          root = root[element]
        end
        target[@name] = root
      end

      def render(data, target)
        self.class.write_to_hash(data, @mapping, target)
      end

      def self.read_from_hash(data, path)

      end

      def self.write_to_hash(data, path, target)
        root = target
        final = path.pop
        path.each do |element|
          root[element] = {} unless root.has_key?(element)
          root = root[element]
        end
        root[final] = data
      end

      # Return the full path and name of this field
      # +path+:: The JSON path or nil, e.g. 'one.two'
      def full_path(path)
        return @name.to_s if path.nil? or path.empty?
        return path.to_s if @name.nil? or @name.empty?
        path+'.'+@name.to_s
      end
    end
  end
end