module ApiTools
  module Presenters
    # A JSON object schema member
    class Object < ApiTools::Presenters::Field

      # The properties of this object, an +array+ of +Field+ instances.
      attr_accessor :properties

      # Initialize an Object instance with the appropriate name and options
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def initialize(name = nil, options = {})
        super name, options
        @properties = {}
      end

      # Define a JSON property with the supplied name, type and options
      # Params
      # +name+:: The JSON key
      # +type+:: A +Class+ for validation
      # +options+:: A +Hash+ of options, e.g. :required => true
      def property(name, type, options = {}, &block)
        inst = type.new name, options.merge({:path => @path + [name]})
        inst.instance_eval &block if block_given?
        @properties[name] = inst
      end

      # Check if data is a valid Object and return either [], or an array with a suitable error
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
        @properties.each do |name, property|
          property.render(data[name], target)
        end
      end

      # Define a JSON object with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      # +&block+:: Block declaring the fields making up the nested object
      def object(name, options = {}, &block)
        raise ArgumentError.new('ApiTools::Presenters::Object must have block') unless block_given?
        property(name, ApiTools::Presenters::Object, options, &block)
      end

      # Define a JSON array with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      # +&block+:: Optional block declaring the fields of each array item
      def array(name, options = {}, &block)
        property(name, ApiTools::Presenters::Array, options, &block)
      end

      # Define a JSON integer with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def integer(name, options = {})
        property(name, ApiTools::Presenters::Integer, options)
      end

      # Define a JSON string with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true, :length => 10
      def string(name, options = {})
        property(name, ApiTools::Presenters::String, options)
      end

      # Define a JSON float with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def float(name, options = {})
        property(name, ApiTools::Presenters::Float, options)
      end

      # Define a JSON decimal with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true, :precision => 10
      def decimal(name, options = {})
        property(name, ApiTools::Presenters::Decimal, options)
      end

      # Define a JSON boolean with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def boolean(name, options = {})
        property(name, ApiTools::Presenters::Boolean, options)
      end

      # Define a JSON date with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def date(name, options = {})
        property(name, ApiTools::Presenters::Date, options)
      end

      # Define a JSON datetime with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def datetime(name, options = {})
        property(name, ApiTools::Presenters::DateTime, options)
      end

      # Define a JSON string of unlimited length with the supplied name
      # and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def text(name, options = {})
        property(name, ApiTools::Presenters::Text, options)
      end

      # Define a JSON string which can only have a restricted set of exactly
      # matched values, with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true and mandatory
      #             :from => [array-of-allowed-strings-or-symbols]
      def enum(name, options = {})
        property(name, ApiTools::Presenters::Enum, options)
      end
      ## ***** DONT FORGET ARRAY & update docs

    end
  end
end