require 'bigdecimal'

module Hoodoo
  module Presenters

    # A JSON Decimal schema member.
    #
    class Decimal < Hoodoo::Presenters::Field

      # In theory this is derived from Rubinius source, but "master" didn't seem
      # to include it at the time of writing. See:
      #
      # https://github.com/rubinius/rubinius/
      # https://stackoverflow.com/questions/1034418/determine-if-a-string-is-a-valid-float-value
      #
      VALIDATOR = Regexp.new('^\s*[+-]?((\d+_?)*\d+(\.(\d+_?)*\d+)?|\.(\d+_?)*\d+)(\s*|([eE][+-]?(\d+_?)*\d+)\s*)$')

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
      # Decimals are expressed in JSON as Strings with any amount of leading or
      # trailing space, can be positive or negative and may use simple (e.g.
      # <tt>"-12.45"</tt>) or scientific (e.g. <tt>"-0.1245e2"</tt>) notation
      # with a lower case or capital <tt>E</tt> in the latter case.
      #
      # A leading "0" before a decimal place may be omitted; "0.12" and ".12"
      # are considered equivalent and valid. An optional leading "+" is allowed
      # for positive numbers. Between digits, an underscore is permitted as a
      # visual separator; "12_431_999" and "12431999" are equivalent and valid.
      #
      def validate( data, path = '' )
        errors = super( data, path )
        return errors if errors.has_errors? || ( ! @required && data.nil? )

        unless data.is_a?( ::String ) && data.match( VALIDATOR ) != nil
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
