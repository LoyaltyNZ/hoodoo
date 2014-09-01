module ApiTools
  module Presenters
    # A JSON float schema member
    class Float < ApiTools::Presenters::Field

      # Check if data is a valid Float and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.count > 0
        return [] if !@required and data.nil?

        unless data.is_a? ::Float
          errors << {:code=> 'generic.invalid_float', :message=>"Field `#{full_path(path)}` is an invalid float", :reference => full_path(path)}
        end
        errors
      end
    end
  end
end