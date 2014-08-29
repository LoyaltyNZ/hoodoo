module ApiTools
  module Presenters
    class Float < ApiTools::Presenters::Field

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