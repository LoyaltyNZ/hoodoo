require 'bigdecimal'

module Hoodoo
  module Presenters

    # A JSON Decimal schema member.
    #
    class Decimal < Hoodoo::Presenters::Field

      # The precision of the Decimal.
      #
      attr_accessor :precision

      # Initialize a Decimal instance with the appropriate name and options.
      #
      # +name+::    The JSON key.
      # +options+:: A +Hash+ of options, e.g. :required => true, :precision => 10.
      #
      def initialize( name, options = {} )
        super( name, options )

        unless options.has_key?( :precision )
          raise ArgumentError.new( 'Hoodoo::Presenters::Decimal must have a :precision' )
        end

        @precision = options[ :precision ]
      end

      # Check if data is a valid Decimal and return a Hoodoo::Errors instance.
      #
      def validate( data, path = '' )
        errors = super( data, path )
        return errors if errors.has_errors? || ( ! @required && data.nil? )

        unless data.is_a?( ::BigDecimal )
          errors.add_error(
            'generic.invalid_decimal',
            :message   => "Field `#{ full_path( path ) }` is an invalid decimal",
            :reference => { :field_name => full_path( path ) }
          )
        end

        errors
      end
    end
  end
end
