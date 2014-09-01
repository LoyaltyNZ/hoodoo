module ApiTools
  module Presenters
    # A JSON boolean schema member
    class Boolean < ApiTools::Presenters::Field

      # Check if data is a valid Boolean and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.count > 0
        return [] if !@required and data.nil?

        unless !!data == data
          errors << {:code=> 'generic.invalid_boolean', :message=>"Field `#{full_path(path)}` is an invalid boolean", :reference => full_path(path)}
        end
        errors
      end
    end
  end
end