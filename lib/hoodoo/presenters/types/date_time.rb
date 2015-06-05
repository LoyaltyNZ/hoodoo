module Hoodoo
  module Presenters
    # A JSON datetime schema member
    class DateTime < Hoodoo::Presenters::Field

      # Check if data is a valid Datetime and return a Hoodoo::Errors instance
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.has_errors? || (!@required and data.nil?)

        #borrowed from http://www.pelagodesign.com/blog/2009/05/20/iso-8601-date-validation-that-doesnt-suck/
        regex = /^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$/
        begin
          valid = (regex=~data.to_s) == 0 && ::DateTime.parse(data).is_a?(::DateTime)
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