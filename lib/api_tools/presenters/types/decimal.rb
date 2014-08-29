require 'bigdecimal'

module ApiTools
  module Presenters
    class Decimal < ApiTools::Presenters::Field

      def initialize(name, options = {})
        super name, options
        raise ArgumentError.new('ApiTools::Presenters::Decimal must have a :precision') unless options.has_key?(:precision)

        @precision = options[:precision]
      end

      def validate(data, path = '')
        errors = super data, path
        return errors unless errors.count == 0

        unless data.is_a? ::BigDecimal
          errors << {:code=> 'generic.invalid_decimal', :message=>"The field at `#{full_path(path)}` is an invalid decimal", :reference => full_path(path) }
        end
        errors
      end
    end
  end
end
