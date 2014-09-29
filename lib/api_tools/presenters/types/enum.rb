module ApiTools
  module Presenters
    # A JSON string schema member. An enumeration (of sorts) - a list of
    # discrete string values that are permitted for the value of a field of
    # this type. Matches must be exact (case sensitive, no leading/trailing
    # white space etc.). Allowed values are expressed as Ruby strings or
    # symbols (converted to and matched as strings) via an array under key
    # +:from+ in the options hash provided to the constructor.
    class Enum < ApiTools::Presenters::Field

      # Permitted values
      attr_accessor :from

      # Initialize a String instance with the appropriate name and options
      # +name+:: The JSON key
      # +options+:: A +Hash+ of options, e.g. :required => true,
      #             :from => [ :array, :of, :allowed, :enum, :values ]
      def initialize(name, options = {})
        super name, options

        @from = options[:from]

        if @from.is_a?( ::Array )
          @from = @from.map { |entry| entry.to_s }
        else
          raise ArgumentError.new('ApiTools::Presenters::Enum must have a :from array listing allowed values')
        end
      end

      # Check if data is a valid String and return either [], or an array with a suitable error
      def validate(data, path = '')
        errors = super data, path
        return errors if errors.count > 0
        return [] if !@required and data.nil?

        if data.is_a? ::String
          unless @from.include?(data)
            errors << {:code=> 'generic.invalid_string', :message=>"Field `#{full_path(path)}` does not contain an allowed reference value from this list: `#{@from}`", :reference => full_path(path)}
          end
        else
          errors << {:code=> 'generic.invalid_string', :message=>"Field `#{full_path(path)}` is an invalid string", :reference => full_path(path)}
        end
        errors
      end
    end
  end
end