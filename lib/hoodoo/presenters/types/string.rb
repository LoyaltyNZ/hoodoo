module Hoodoo
  module Presenters

    # A JSON String schema member.
    #
    class String < Hoodoo::Presenters::Field

      # The maximum length of the String.
      #
      attr_accessor :length

      # Initialize a String instance with the appropriate name and options.
      #
      # +name+::    The JSON key.
      # +options+:: A +Hash+ of options, e.g. :required => true, :length => 10.
      #
      def initialize( name, options = {} )
        super( name, options )

        unless options.has_key?( :length )
          raise ArgumentError.new( 'Hoodoo::Presenters::String must have a :length' )
        end

        @length = options[ :length ]
      end

      # Check if data is a valid String and return a Hoodoo::Errors instance.
      #
      def validate( data, path = '' )
        errors = super( data, path )
        return errors if errors.has_errors? || ( ! @required && data.nil? )

        if data.is_a?( ::String )
          if data.size > @length
            errors.add_error(
              'generic.invalid_string',
              :message   => "Field `#{ full_path( path ) }` is longer than maximum length `#{ @length }`",
              :reference => { :field_name => full_path( path ) }
            )
          end
        else
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