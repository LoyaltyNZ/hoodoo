module Hoodoo
  module Presenters
    # A JSON integer schema member
    class Integer < Hoodoo::Presenters::Field

      # Check if data is a valid Integer and return a Hoodoo::Errors instance
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.has_errors? || (!@required and data.nil?)

        unless data.is_a? ::Integer
          errors.add_error(
            'generic.invalid_integer',
            :message   => "Field `#{ full_path( path ) }` is an invalid integer",
            :reference => { :field_name => full_path( path ) }
          )
        end

        errors
      end
    end
  end
end