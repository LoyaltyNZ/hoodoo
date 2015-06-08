module Hoodoo
  module Presenters
    # A JSON datetime schema member
    class DateTime < Hoodoo::Presenters::Field
      
      # Check if data is a valid Datetime and return a Hoodoo::Errors instance
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.has_errors? || (!@required and data.nil?)

        begin
          # This will parse dates as defined by W3 XmlSchame spec http://www.w3.org/TR/xmlschema-2/#dateTime
          Time.iso8601( data.to_s )
          valid = true
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