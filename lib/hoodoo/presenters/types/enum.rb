module Hoodoo
  module Presenters

    # A JSON String schema member. An enumeration (of sorts) - a list of
    # discrete string values that are permitted for the value of a field of
    # this type. Matches must be exact (case sensitive, no leading/trailing
    # white space etc.). Allowed values are expressed as Ruby strings or
    # symbols (converted to and matched as strings) via an array under key
    # +:from+ in the options hash provided to the constructor.
    #
    class Enum < Hoodoo::Presenters::Field

      # Array of permitted enumeration values. This may be written with
      # non-String values but they will be converted to Strings when read
      # back.
      #
      attr_accessor :from

      # Initialize a String instance with the appropriate name and options.
      #
      # +name+::    The JSON key.
      # +options+:: A +Hash+ of options, e.g. :required => true,
      #             :from => [ :array, :of, :allowed, :enum, :values ].
      #
      def initialize( name, options = {} )
        super( name, options )

        @from = options[ :from ]

        if @from.is_a?( ::Array )
          @from = @from.map { | entry | entry.to_s }
        else
          raise ArgumentError.new( 'Hoodoo::Presenters::Enum must have a :from array listing allowed values' )
        end
      end

      # Check if data is a valid String and return a Hoodoo::Errors instance.
      #
      def validate( data, path = '' )
        errors = super( data, path )
        return errors if errors.has_errors? || ( ! @required && data.nil? )

        unless @from.include?( data )
          errors.add_error(
            'generic.invalid_enum',
            :message   => "Field `#{ full_path( path ) }` does not contain an allowed reference value from this list: `#{@from}`",
            :reference => { :field_name => full_path( path ) }
          )
        end

        errors
      end
    end
  end
end