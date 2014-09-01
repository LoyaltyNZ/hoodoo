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
        @properties = []
      end

      # Define a JSON property with the supplied name, type and options
      # Params
      # +name+:: The JSON key
      # +type+:: A +Class+ for validation
      # +options+:: A +Hash+ of options, e.g. :required => true
      def property(name, type, options = {}, &block)
        inst = type.new name, options
        inst.instance_eval &block if block_given?
        @properties << inst
      end

      # Check if data is a valid Object and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path

        return [] if !@required and data.nil?

        if !data.nil? and !data.is_a? ::Hash
          errors << {:code=> 'generic.invalid_object', :message=>"Field `#{full_path(path)}` is an invalid object", :reference => full_path(path)}
        end

        @properties.each do |property|
          rdata = (data.is_a?(::Hash) and data.has_key?(property.name)) ? data[property.name] : nil
          errors += property.validate(rdata, full_path(path))
        end
        errors
      end

      # Define a JSON object with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def object(name, options = {}, &block)
        raise ArgumentError.new('ApiTools::Presenters::Object must have block') unless block_given?
        property(name, ApiTools::Presenters::Object, options, &block)
      end

      # Define a JSON array with the supplied name and options
      # Params
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true
      def array(name, options = {})
        property(name, ApiTools::Presenters::Array, options)
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
      # +options+:: A +Hash+ of options, e.g. :required => true, :length => 20
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
      # +options+:: A +Hash+ of options, e.g. :required => true
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
    end
  end
end