module Hoodoo
  module Presenters

    # A JSON Date schema member.
    #
    class Date < Hoodoo::Presenters::Field

      # Check if data is a valid Date and return a Hoodoo::Errors instance.
      #
      def validate( data, path = '' )
        errors = super( data, path )
        return errors if errors.has_errors? || ( ! @required && data.nil? )

        unless Hoodoo::Utilities.valid_iso8601_subset_date?( data )
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