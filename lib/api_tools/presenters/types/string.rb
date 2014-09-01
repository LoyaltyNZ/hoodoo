module ApiTools
  module Presenters
    # A JSON string schema member
    class String < ApiTools::Presenters::Field

      # The maximum length of the string
      attr_accessor :length

      # Initialize a String instance with the appropriate name and options
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true, :length => 10
      def initialize(name, options = {})
        super name, options
        raise ArgumentError.new('ApiTools::Presenters::String must have a :length') unless options.has_key?(:length)
        @length = options[:length]
      end

      # Check if data is a valid String and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.count > 0
        return [] if !@required and data.nil?

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