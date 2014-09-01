module ApiTools
  module Presenters
    # A JSON array schema member
    class Array < ApiTools::Presenters::Field

      # Check if data is a valid Array and return either [], or an array with a suitable error
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