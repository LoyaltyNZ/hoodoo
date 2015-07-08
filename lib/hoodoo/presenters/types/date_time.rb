module Hoodoo
  module Presenters

    # A JSON DateTime schema member.
    #
    class DateTime < Hoodoo::Presenters::Field

      # Validation regular expression for DateTime subset selection.
      #
      VALIDATION_REGEXP = /(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})\:(\d{2})(Z|[+-](\d{2})\:(\d{2}))/

      # Check if data is a valid DateTime and return a Hoodoo::Errors instance.
      #
      def validate( data, path = '' )
        errors = super( data, path )
        return errors if errors.has_errors? || ( ! @required && data.nil? )

        begin
          valid = ( VALIDATION_REGEXP =~ data.to_s ) == 0 &&
                  data.size > 10                          &&
                  ::DateTime.parse( data ).is_a?( ::DateTime )

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