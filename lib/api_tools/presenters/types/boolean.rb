module ApiTools
  module Presenters
  class Boolean < ApiTools::Presenters::Field

    def validate(data, path = '')
      errors = super data, path
      return errors unless errors.count == 0

      unless !!data == data
        errors << {:code=> 'generic.invalid_boolean', :message=>"The field at `#{full_path(path)}` is an invalid boolean", :reference => full_path(path)}
      end
      errors
    end
  end
end
end