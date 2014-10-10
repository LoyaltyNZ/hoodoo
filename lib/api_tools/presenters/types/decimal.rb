require 'bigdecimal'

module ApiTools
  module Presenters
    # A JSON decimal schema member
    class Decimal < ApiTools::Presenters::Field

      # The precision of the decimal
      attr_accessor :precision

      # Initialize a Decimal instance with the appropriate name and options
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true, :precision => 10
      def initialize(name, options = {})
        super name, options
        raise ArgumentError.new('ApiTools::Presenters::Decimal must have a :precision') unless options.has_key?(:precision)

        @precision = options[:precision]
      end

      # Check if data is a valid Decimal and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.count > 0
        return [] if !@required and data.nil?

        unless data.is_a? ::BigDecimal
          errors << {'code'=> 'generic.invalid_decimal', 'message'=>"Field `#{full_path(path)}` is an invalid decimal", 'reference' => full_path(path) }
        end
        errors
      end
    end
  end
end
