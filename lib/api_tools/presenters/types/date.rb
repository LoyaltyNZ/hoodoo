module ApiTools
  module Presenters
    # A JSON date schema member
    class Date < ApiTools::Presenters::Field

      # Check if data is a valid Date and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.has_errors? || (!@required and data.nil?)

        begin
          valid = (/(\d{4})-(\d{2})-(\d{2})/=~data.to_s) == 0 && data.size == 10 && ::Date.parse(data).is_a?(::Date)
        rescue ArgumentError
          valid = false
        end

        unless valid
          errors.add_error(
            'generic.invalid_date',
            :message   => "Field `#{ full_path( path ) }` is an invalid ISO8601 date",
            :reference => { :field_name => full_path( path ) }
          )
        end

        errors
      end
    end
  end
end