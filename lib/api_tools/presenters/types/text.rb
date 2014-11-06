module ApiTools
  module Presenters
    # A JSON string schema member - unlimited length string
    class Text < ApiTools::Presenters::Field

      # Check if data is a valid String and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.has_errors? || (!@required and data.nil?)

        unless data.is_a? ::String
          errors.add_error(
            'generic.invalid_string',
            :message   => "Field `#{ full_path( path ) }` is an invalid string",
            :reference => { :field_name => full_path( path ) }
          )
        end

        errors
      end
    end
  end
end