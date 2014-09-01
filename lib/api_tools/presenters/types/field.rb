module ApiTools
  module Presenters
    class Field

      attr_accessor :name, :required

      def initialize(name, options = {})
        @name = name
        @required = options.has_key?(:required) ? options[:required] : false
      end

      # Check if data is required and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = []
        if data.nil? and @required
          errors << {:code=> 'generic.required_field_missing', :message=>"Field `#{full_path(path)}` is required", :reference => full_path(path)}
        end
        errors
      end

      def full_path(path)
        return @name.to_s if path.nil? or path.empty?
        return path.to_s if @name.nil? or @name.empty?
        path+'.'+@name.to_s
      end
    end
  end
end