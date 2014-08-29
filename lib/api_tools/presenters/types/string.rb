module ApiTools
  module Presenters
    class String < ApiTools::Presenters::Field

      attr_accessor :length

      def initialize(name, options = {})
        super name, options
        raise ArgumentError.new('ApiTools::Presenters::String must have a :length') unless options.has_key?(:length)
        @length = options[:length]
      end

      def validate(data, path = '')
        errors = super data, path
        return errors unless errors.count == 0

        if data.is_a? ::String
          if data.size > @length
            errors << {:code=> 'generic.max_length_exceeded', :message=>"Field `#{full_path(path)}` is larger than max length `#{@length}`", :reference => full_path(path)}
          end
        else
          errors << {:code=> 'generic.invalid_string', :message=>"Field `#{full_path(path)}` is an invalid string", :reference => full_path(path)}
        end
        errors
      end
    end
  end
end