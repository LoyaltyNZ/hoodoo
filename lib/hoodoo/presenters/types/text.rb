module Hoodoo
  module Presenters

    # A JSON String schema member - unlimited length String.
    #
    class Text < Hoodoo::Presenters::Field

      # Check if data is a valid String and return a Hoodoo::Errors instance.
      #
      def validate( data, path = '' )
        errors = super( data, path )
        return errors if errors.has_errors? || ( ! @required && data.nil? )

        unless data.is_a?( ::String )
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