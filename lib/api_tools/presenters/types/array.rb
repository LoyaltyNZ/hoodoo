module ApiTools
  module Presenters
    class Array < ApiTools::Presenters::Field

      def initialize(name, options = {})
        super name, options
      end

      def validate(data, path = '')
        errors = super data, path
        return errors if errors.count > 0
        return [] if !@required and data.nil?

        unless data.is_a? ::Array
          errors << {:code=> 'generic.invalid_array', :message=>"Field `#{full_path(path)}` is an invalid array", :reference => full_path(path)}
        end
        errors

      end
    end
  end
end