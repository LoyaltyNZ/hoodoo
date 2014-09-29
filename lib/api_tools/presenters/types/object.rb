module ApiTools
  module Presenters
    # A JSON object schema member
    class Object < ApiTools::Presenters::Field

      include ApiTools::Presenters::BaseDSL

      # The properties of this object, an +array+ of +Field+ instances.
      attr_accessor :properties

      # Initialize an Object instance with the appropriate name and options
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def initialize(name = nil, options = {})
        super name, options
        @properties = {}
      end

      # Check if data is a valid Object and return either [], or an array with
      # a suitable error.
      #
      # +data+: Data to check (and check nested properties therein). Expected
      #         to be nil (unless field is required) or a Hash.
      #
      # +path+: For internal callers only in theory. The nesting human-readable
      #         path to this "level", as an array. Omitted at the top level.
      #         In :errors => { :foo => { ... } }, validation of ":foo" would
      #         be at path "[ :errors ]". Validation of the contents of the
      #         object at ":foo" would be under "[ :errors, :foo ]".
      #
      def validate(data, path = '')
        errors = super data, path

        return [] if !@required and data.nil?

        if !data.nil? and !data.is_a? ::Hash
          errors << {:code=> 'generic.invalid_object', :message=>"Field `#{full_path(path)}` is an invalid object", :reference => full_path(path)}
        end

        @properties.each do |name, property|
          rdata = (data.is_a?(::Hash) and data.has_key?(name)) ? data[name] : nil
          errors += property.validate(rdata, full_path(path))
        end
        errors
      end

      def parse(data, target)
        target[@name] = {}
        @properties.each do |name, property|
          property.parse(data, target[@name])
        end
        target[@name]
      end

      def render(data, target)
        puts "*"*80
        puts "Render current target #{target.inspect}"
        puts "Data is #{data.inspect}"
        puts "Properties #{@properties.inspect}"
        @properties.each do |name, property|
          puts "Property name #{name} => #{property.inspect}"
          property.render(data[name], target)
        end
      end
    end
  end
end