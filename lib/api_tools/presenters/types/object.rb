module ApiTools
  module Presenters
    class Object < ApiTools::Presenters::Field

      attr_accessor :properties

      def initialize(name = nil, options = {})
        super name, options
        @properties = []
      end

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

      def object(name, options = {}, &block)
        raise ArgumentError.new('ApiTools::Presenters::Object must have block') unless block_given?
        property(name, ApiTools::Presenters::Object, options, &block)
      end

      def array(name, options = {})
        property(name, ApiTools::Presenters::Array, options)
      end

      def integer(name, options = {})
        property(name, ApiTools::Presenters::Integer, options)
      end

      def string(name, options = {})
        property(name, ApiTools::Presenters::String, options)
      end

      def float(name, options = {})
        property(name, ApiTools::Presenters::Float, options)
      end

      def decimal(name, options = {})
        property(name, ApiTools::Presenters::Decimal, options)
      end

      def boolean(name, options = {})
        property(name, ApiTools::Presenters::Boolean, options)
      end

      def date(name, options = {})
        property(name, ApiTools::Presenters::Date, options)
      end

      def datetime(name, options = {})
        property(name, ApiTools::Presenters::DateTime, options)
      end
    end
  end
end