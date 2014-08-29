module ApiTools
  module Presenters
    class Date < ApiTools::Presenters::Field

      def validate(data, path = '')
        errors = super data, path
        return errors unless errors.count == 0

        begin
          valid = (/(\d{4})-(\d{2})-(\d{2})/=~data.to_s) == 0 && data.size == 10 && ::Date.parse(data).is_a?(::Date)
        rescue ArgumentError
          valid = false
        end

        unless valid
          errors << {:code=> 'generic.invalid_date', :message=>"The field at `#{full_path(path)}` is an invalid ISO8601 date", :reference => full_path(path)}
        end
        errors
      end
    end
  end
end