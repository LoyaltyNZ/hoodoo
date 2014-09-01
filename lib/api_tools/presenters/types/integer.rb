module ApiTools
  module Presenters
    class Integer < ApiTools::Presenters::Field

      # Check if data is a valid Integer and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.count > 0
        return [] if !@required and data.nil?

        unless data.is_a? ::Integer
          errors << {:code=> 'generic.invalid_integer', :message=>"Field `#{full_path(path)}` is an invalid integer", :reference => full_path(path)}
        end
        errors
      end
    end
  end
end