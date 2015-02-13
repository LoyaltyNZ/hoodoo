module Hoodoo
  module Presenters
    # A JSON float schema member
    class Float < Hoodoo::Presenters::Field

      # Check if data is a valid Float and return a Hoodoo::Errors instance
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.has_errors? || (!@required and data.nil?)

        unless data.is_a? ::Float
          errors.add_error(
            'generic.invalid_float',
            :message   => "Field `#{ full_path( path ) }` is an invalid float",
            :reference => { :field_name => full_path( path ) }
          )
        end

        errors
      end
    end
  end
end