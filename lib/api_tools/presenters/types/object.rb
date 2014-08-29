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

      def validate(data, path = '')
        errors = super data, path
        return errors unless errors.count == 0

        unless data.is_a? ::Hash
          errors << {:code=> 'generic.invalid_object', :message=>"The field at `#{full_path(path)}` is an invalid object", :reference => full_path(path)}
        end

        @properties.each do |property|
          errors += property.validate(data[property.name], full_path(path))
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