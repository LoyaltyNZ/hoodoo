module Hoodoo
  module Presenters
    # A JSON datetime schema member
    class DateTime < Hoodoo::Presenters::Field

      # Check if data is a valid Datetime and return an Hoodoo::Errors instance
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.has_errors? || (!@required and data.nil?)

        begin
          valid = (/(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})\:(\d{2})(Z|[+-](\d{2})\:(\d{2}))/=~data.to_s) == 0 && data.size>10 && ::DateTime.parse(data).is_a?(::DateTime)
        rescue ArgumentError
          valid = false
        end

        unless valid
          errors.add_error(
            'generic.invalid_datetime',
            :message   => "Field `#{ full_path( path ) }` is an invalid ISO8601 datetime",
            :reference => { :field_name => full_path( path ) }
          )
        end

        errors
      end
    end
  end
end