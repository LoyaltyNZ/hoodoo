module ApiTools
  module Presenters
    class Integer < ApiTools::Presenters::Field

      def validate(data, path = '')
        errors = super data, path
        return errors unless errors.count == 0

        unless data.is_a? ::Integer
          errors << {:code=> 'generic.invalid_integer', :message=>"The field at `#{full_path(path)}` is an invalid integer", :reference => full_path(path)}
        end
        errors
      end
    end
  end
end